import { makeCompletionRequest } from './lib';
import chalk from 'chalk';

async function main() {
	const API_KEY = process.env.API_KEY || '';
	const BASE_URL = process.env.BASE_URL || 'https://api.atoma.network';
	const MODEL = process.env.MODEL || 'meta-llama/Llama-3.3-70B-Instruct';
	console.log('\nAPI Health Check');
	console.log('==============\n');

	try {
		await makeCompletionRequest(API_KEY, BASE_URL, MODEL);
		console.log(`Status: ${chalk.green('●')} 200 OK`);
	} catch (error: any) {
		const statusCode = error.response?.status || 'Unknown';
		console.log(`Status: ${chalk.red('●')} ${statusCode} Error`);
		console.error('Error details:', error.message);
	}
}

main().catch(console.error);


