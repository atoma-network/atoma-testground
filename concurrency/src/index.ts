import { AtomaSDK } from 'atoma-sdk';
import dotenv from 'dotenv';
import { setTimeout } from 'timers/promises';
dotenv.config();

/**
 * Get a random sleep time between baseTime and baseTime + deviation * baseTime
 * @param baseTime - The base time in milliseconds
 * @param deviation - The deviation from the base time in percentage (default: 0.2 or 20%)
 * @returns The random sleep time in milliseconds
 */
function getRandomSleepTime(baseTime: number, deviation: number = 0.2) {
  const sleepTime = baseTime + (Math.random() * 2 - 1) * deviation * baseTime;
  return sleepTime;
}

/**
 * Makes a single request to the Atoma API with the given prompt
 * @param prompt - The prompt to send to the API
 * @returns Promise<string> - The response from the API
 * @throws Will throw an error if the API request fails
 */
async function singleRequest(prompt: string): Promise<number> {
  const atomaSdk = new AtomaSDK({
    bearerAuth: process.env.ATOMA_BEARER_TOKEN,
    serverURL: 'https://api.atoma.network',
  });

  const chatCompletionsRequest = {
    model: 'Infermatic/Llama-3.3-70B-Instruct-FP8-Dynamic',
    messages: [
      {
        role: 'user',
        content: prompt,
      },
    ],
    maxTokens: 512,
  };

  const chatCompletions = await atomaSdk.chat.create(chatCompletionsRequest);
  const totalTokens = chatCompletions.usage?.totalTokens ?? 0;
  return totalTokens;
}

/**
 * Processes a batch of requests concurrently
 * @param startIndex - The starting index for this batch
 * @param batchSize - The number of requests to process in this batch
 * @param sleepTime - Base sleep time between requests in milliseconds
 * @returns Promise<void>
 */
async function processBatch(
  startIndex: number,
  batchSize: number,
  sleepTime: number,
): Promise<number> {
  for (let i = startIndex; i < startIndex + batchSize; i++) {
    if (i >= 10000) break;

    try {
      const prompt = `Explain me in detail the memory hierarchy of modern GPUs, including SRAM, DRAM, cache, HBM, etc.`;
      const totalTokens = await singleRequest(prompt);
      console.log(totalTokens);

      // Sleep for a random time before sending the next request
      const sleepDuration = getRandomSleepTime(sleepTime);
      await setTimeout(sleepDuration);
      return totalTokens;
    } catch (error) {
      console.error(error);
    }
  }
  return 0;
}

/**
 * Runs multiple concurrent batches of API requests
 * @param maxConcurrency - The maximum number of concurrent batch processes
 * @param sleepTime - Base sleep time between requests in milliseconds (default: 5000ms)
 *
 * @example
 * ```typescript
 * // Run 10,000 requests with 32 concurrent batches and 5 second sleep time
 * run(32, 5000);
 * ```
 *
 * @remarks
 * - Total requests are fixed at 10,000
 * - Each batch processes requests concurrently
 * - Actual sleep time includes random deviation of ±20%
 * - Batch size is calculated as totalRequests / maxConcurrency
 *
 * @throws Will throw an error if any batch process fails
 */
async function run(maxConcurrency: number, sleepTime: number = 5_000) {
  const totalRequests = 10_000;
  const batchSize = Math.ceil(totalRequests / maxConcurrency);
  let totalTokens = 0;
  const batches = Array.from({ length: maxConcurrency }, async (_, i) => {
    const tokens = await processBatch(i * batchSize, batchSize, sleepTime);
    totalTokens += tokens;
  });
  console.log(
    `Starting ${totalRequests} requests in ${maxConcurrency} batches of ${batchSize} requests`,
  );

  await Promise.all(batches);
  console.log('All requests completed');
  console.log(`Total tokens: ${totalTokens}`);
}

/* 
We run 32 requests in parallel, with a sleep time of 5 seconds between each request.
*/
run(32, 5_000).catch(console.error);

// runExample();
