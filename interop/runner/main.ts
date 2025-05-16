import { AtomaSDK } from "atoma-sdk";

async function runE2ETests() {
	const apiKey = process.env.ATOMA_API_KEY;
	if (!apiKey) {
		throw new Error("ATOMA_API_KEY is not set");
	}
	if (!process.env.ATOMA_API_URL) {
		throw new Error("ATOMA_API_URL is not set");
	}
	const sdk = new AtomaSDK({
		serverURL: process.env.ATOMA_API_URL,
		bearerAuth: apiKey,
	});

	try {
		console.log("Running tests against:", process.env.ATOMA_API_URL);
		const startTime = Date.now();

		// Health check
		const health = await sdk.health.health();
		console.log("Health check passed:", health.message);

		// Test chat completions
		const chatResponse = await sdk.chat.create({
			messages: [
				{ role: "user", content: "Explain the difference between a cat and a dog" }
			],
			model: "deepseek-ai/DeepSeek-V3-0324",
			stream: false,
		});

		console.log("Chat response:", chatResponse.choices[0].message.content);

		const endTime = Date.now();
		const timeTaken = (endTime - startTime) / 1000;
		console.log(`Time taken: ${timeTaken.toFixed(2)} seconds`);

		console.log("All tests passed successfully");
		process.exit(0);
	} catch (error) {
		console.error("Test failed:", error);
		process.exit(1);
	}
}

runE2ETests().then(() => {
	console.log("All tests passed successfully");
	process.exit(0);
}).catch((error) => {
	console.error("Test failed:", error);
	process.exit(1);
});