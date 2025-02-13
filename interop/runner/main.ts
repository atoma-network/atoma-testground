import { AtomaSDK } from "atoma-sdk";

async function runE2ETests() {
	const sdk = new AtomaSDK({
		baseUrl: process.env.ATOMA_API_URL || "http://localhost:8080",
		bearerAuth: process.env.ATOMA_API_KEY || "test-key"
	});

	try {
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

		// Test embeddings
		const embeddingResponse = await sdk.embeddings.create({
			model: "intfloat/multilingual-e5-large-instruct",
			input: "Test embedding generation"
		});
		console.log("Embedding generation successful, dimensions:", embeddingResponse.data[0].embedding.length);

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