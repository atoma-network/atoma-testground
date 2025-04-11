import { AtomaSDK } from "atoma-sdk";
import { createAccount } from "./create-account";

async function runE2ETests(apiKey: string) {
	const sdk = new AtomaSDK({
		serverURL: process.env.ATOMA_API_URL || "http://localhost:8081",
		bearerAuth: apiKey,
	});

	try {
		console.log("Running tests against:", process.env.ATOMA_API_URL);
		// Health check
		const health = await sdk.health.health();
		console.log("Health check passed:", health.message);

		// Test chat completions
		const chatResponse = await sdk.chat.create({
			messages: [
				{ role: "user", content: "Hello, are you operational?" }
			],
			model: "meta-llama/Llama-3.3-70B-Instruct"
		});

		console.log("Chat completion successful:", chatResponse.choices[0].message.content);

		console.log("All tests passed successfully");
		process.exit(0);
	} catch (error) {
		console.error("Test failed:", error);
		process.exit(1);
	}
}

getApiKey().then((apiKey) => {
	runE2ETests(apiKey).then(() => {
		runE2ETests(apiKey).then(() => {
			console.log("All tests passed successfully");
			process.exit(0);
		}).catch((error) => {
			console.error("Test failed:", error);
			process.exit(1);
		});
	});
});
