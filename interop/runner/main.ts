import { AtomaSDK } from "atoma-sdk";

async function runE2ETests() {
	const apiKey = process.env.ATOMA_API_KEY;
	if (!apiKey) {
		throw new Error("ATOMA_API_KEY is not set");
	}
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
			model: "TinyLlama/TinyLlama-1.1B-Chat-v1.0"
		});

		console.log("Chat response:", chatResponse.choices[0].message.content);

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