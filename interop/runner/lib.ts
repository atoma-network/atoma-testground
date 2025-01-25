import axios from 'axios';

export async function makeCompletionRequest(apiKey: string, baseUrl: string, model: string) {
	const url = `${baseUrl}/v1/chat/completions`;

	try {
		const response = await axios.post(url, {
			model,
			messages: [
				{
					role: "user",
					content: "Tell me a joke"
				}
			],
			max_tokens: 4096,
			stream: true
		}, {
			headers: {
				'Authorization': `Bearer ${apiKey}`,
				'Content-Type': 'application/json'
			}
		});

		if (response.status !== 200) {
			throw new Error(`Request failed with status ${response.status}`);
		}

		return response.data;
	} catch (error) {
		console.error('Error making completion request:', error);
		throw error;
	}
}
