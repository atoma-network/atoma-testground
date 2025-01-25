# End to end test dev environment for the Atoma Network


[![Made by Atoma Network](https://img.shields.io/badge/made%20by-Atoma%20Network-blue.svg?style=flat-square)](https://atoma.network)

This repository contains an end to end test dev environment for the Atoma Network. This can be be run locally or in a CI environment.

Ideally in the future this can be used to run performance benchmarks for the Atoma Network across various network conditions.


## Environment Variables

The following environment variables are required to run the environment:

- `HF_TOKEN`: A Hugging Face token for accessing the HF Token Registry.
- `VLLM_ENDPOINT`: The endpoint of the vLLM service you want to use
- `SUI_RPC_ENDPOINT`: The endpoint of the Sui network you want to use
- `SUI_CONTRACT_ADDRESS`: The address of the Sui contract you want to use
- `ATOMA_NODE_BADGE_ID`: This will be tied the node badge id of the SUI contract address, this is used to route the request to the correct node.

## License

Dual-licensed: [MIT](./LICENSE-MIT), [Apache Software License v2](./LICENSE-APACHE), by way of the
[Permissive License Stack](https://protocol.ai/blog/announcing-the-permissive-license-stack/).
