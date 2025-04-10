

export async function createAccount(url: string): Promise<string> {
	const account = await sdk.account.create({
		email: "test@test.com",
		password: "test",
	});
}
