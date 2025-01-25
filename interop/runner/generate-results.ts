import * as fs from 'fs';
import * as path from 'path';

interface TestResult {
	model: string;
	prompt: string;
	response: string;
	latency: number;
	timestamp: string;
}

function generateResultsCsv(results: TestResult[], outputPath: string): void {
	// Create CSV header
	const header = ['Model', 'Prompt', 'Response', 'Latency (ms)', 'Timestamp'].join(',');

	// Convert results to CSV rows
	const rows = results.map(result => {
		// Escape fields that might contain commas
		const escapedPrompt = `"${result.prompt.replace(/"/g, '""')}"`;
		const escapedResponse = `"${result.response.replace(/"/g, '""')}"`;

		return [
			result.model,
			escapedPrompt,
			escapedResponse,
			result.latency,
			result.timestamp
		].join(',');
	});

	// Combine header and rows
	const csvContent = [header, ...rows].join('\n');

	// Ensure output directory exists
	const dir = path.dirname(outputPath);
	if (!fs.existsSync(dir)) {
		fs.mkdirSync(dir, { recursive: true });
	}

	// Write to file
	fs.writeFileSync(outputPath, csvContent);
	console.log(`Results written to ${outputPath}`);
}
