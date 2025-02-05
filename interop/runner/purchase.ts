import {
	JsonRpcProvider,
	Connection,
	TransactionBlock,
	SuiClient,
	SuiTransactionBlockResponse
} from '@mysten/sui';

interface StackCreatedEvent {
	// Add your event type definition based on the actual event structure
	stack_id: string;
	task_small_id: string;
	compute_units: string;
	// Add other relevant fields
}

interface StackEntryResponse {
	transaction_digest: string;
	stack_created_event: StackCreatedEvent;
	timestamp_ms: number;
}


const ONE_MILLION = 1_000_000;
const GAS_BUDGET = 50_000_000; // Adjust based on your needs

export class AtomaStackPurchaser {
	private suiClient: SuiClient;
	private atomaPackageId: string;
	private atomaDbId: string;
	private usdcPackageId: string;
	private senderAddress: string;

	constructor(config: AtomaStackPurchaser) {
		this.suiClient = config.suiClient;
		this.atomaPackageId = config.atomaPackageId;
		this.atomaDbId = config.atomaDbId;
		this.usdcPackageId = config.usdcPackageId;
		this.senderAddress = config.senderAddress;
	}

	async getCoinsOfValue(coinType: string | null, requiredValue: number): Promise<string[]> {
		const coins = await this.suiClient.getCoins({
			owner: this.senderAddress,
			coinType: coinType || '0x2::sui::SUI'
		});

		let totalValue = 0n;
		const selectedCoins: string[] = [];

		for (const coin of coins.data) {
			if (totalValue >= BigInt(requiredValue)) break;
			totalValue += BigInt(coin.balance);
			selectedCoins.push(coin.coinObjectId);
		}

		if (totalValue < BigInt(requiredValue)) {
			throw new Error(`Insufficient coins. Required: ${requiredValue}, Available: ${totalValue}`);
		}

		return selectedCoins;
	}

	async acquireNewStackEntry(
		taskSmallId: number,
		numComputeUnits: number,
		pricePerOneMillionComputeUnits: number
	): Promise<StackEntryResponse> {
		// Calculate total USDC required
		const totalUsdcValueRequired =
			(numComputeUnits * pricePerOneMillionComputeUnits) / ONE_MILLION;

		// Get USDC coins
		const usdcCoinType = `${this.usdcPackageId}::usdc::USDC`;
		const usdcCoins = await this.getCoinsOfValue(usdcCoinType, totalUsdcValueRequired);

		// Create transaction block
		const tx = new TransactionBlock();

		// Add USDC coins to transaction
		const primaryCoin = tx.object(usdcCoins[0]);
		if (usdcCoins.length > 1) {
			const remainingCoins = usdcCoins.slice(1).map(coin => tx.object(coin));
			tx.mergeCoins(primaryCoin, remainingCoins);
		}

		// Get shared objects' initial versions
		const [atomaDbObject] = await this.suiClient.getObject({
			id: this.atomaDbId,
			options: { showPreviousTransaction: true }
		});

		const [randomnessStateObject] = await this.suiClient.getObject({
			id: '0x0000000000000000000000000000000000000000000000000000000000000005',
			options: { showPreviousTransaction: true }
		});

		if (!atomaDbObject.data?.objectId || !randomnessStateObject.data?.objectId) {
			throw new Error('Failed to fetch required objects');
		}

		// Add move call
		tx.moveCall({
			target: `${this.atomaPackageId}::db::acquire_new_stack_entry`,
			arguments: [
				tx.sharedObject({
					id: this.atomaDbId,
					initialSharedVersion: atomaDbObject.data.previousTransaction as string,
					mutable: true
				}),
				primaryCoin,
				tx.pure(taskSmallId),
				tx.pure(numComputeUnits),
				tx.pure(pricePerOneMillionComputeUnits),
				tx.sharedObject({
					id: '0x0000000000000000000000000000000000000000000000000000000000000005',
					initialSharedVersion: randomnessStateObject.data.previousTransaction as string,
					mutable: false
				})
			]
		});

		// Set gas budget
		const gasPrice = await this.suiClient.getReferenceGasPrice();
		tx.setGasBudget(GAS_BUDGET);

		// Execute transaction
		console.log('Submitting acquire new stack entry transaction...');
		const response = await this.suiClient.signAndExecuteTransactionBlock({
			transactionBlock: tx,
			requestType: 'WaitForLocalExecution',
			options: {
				showEvents: true,
			}
		});

		console.log(
			'Acquire new stack entry transaction submitted successfully.',
			'Transaction digest:', response.digest
		);

		// Parse response
		if (!response.events || response.events.length === 0) {
			throw new Error('No stack created event');
		}

		const stackCreatedEvent = response.events[0];

		return {
			transaction_digest: response.digest,
			stack_created_event: stackCreatedEvent.parsedJson as StackCreatedEvent,
			timestamp_ms: Date.now() // Note: Using current timestamp as Sui response doesn't include it
		};
	}
}

// Usage example:
/*
const purchaser = new AtomaStackPurchaser({
  suiClient: new SuiClient({ url: 'https://sui-mainnet-rpc.example.com' }),
  atomaPackageId: '0x...', // Your Atoma package ID
  atomaDbId: '0x...', // Your Atoma DB ID
  usdcPackageId: '0x...', // USDC package ID
  senderAddress: '0x...' // Your wallet address
});

const response = await purchaser.acquireNewStackEntry(
  123, // taskSmallId
  1000000, // numComputeUnits
  100 // pricePerOneMillionComputeUnits
);
console.log('Stack entry purchased:', response);
*/