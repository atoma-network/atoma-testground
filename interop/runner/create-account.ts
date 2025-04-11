import axios from "axios";


export async function createAccount(): Promise<{ refreshToken: string, accessToken: string }> {
	const email = "email";
	const salt = "salt";
	const password = "top_secret";

	const { data } = await axios.post(`${process.env.ATOMA_API_URL}/register`, {
		email,
		password,
	});

	return { refreshToken: data.refreshToken, accessToken: data.accessToken };
}


export async function generateApiToken(jwt: string, name: string): Promise<string> {
	const { data } = await axios.post(`${process.env.ATOMA_API_URL}/generate_api_token`, {
		jwt,
		name,
	});

	return data.apiToken;
}

export async function fund(refreshToken: string): Promise<string> {
	const { data } = await axios.post(`${process.env.ATOMA_API_URL}/fund`, {
		refreshToken,
	});

	return data.apiToken;
}
