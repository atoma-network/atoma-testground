# End to end test dev environment for the Atoma Network


[![Made by Atoma Network](https://img.shields.io/badge/made%20by-Atoma%20Network-blue.svg?style=flat-square)](https://atoma.network)

This repository contains an end to end test dev environment for the Atoma Network. This can be be run locally or in a CI environment.

Ideally in the future this can be used to run performance benchmarks for the Atoma Network across various network conditions.


## Architecture

```mermaid
flowchart TD
 subgraph subGraph0["Local Dev/CI Environment"]
        AtomaProxy["Atoma Proxy Node"]
        AtomaNode["Atoma Node"]
        vLLMService["vLLM Service"]
        PrometheusClient["Prometheus Client"]
  end
    AtomaProxy -- Forward Request --> AtomaNode
    AtomaNode -- Download model weights --> HuggingFace["HF Token Registry"]
    AtomaNode -- Cache model weights --> HuggingFaceCachingService
    AtomaNode -- vLLM Request --> vLLMService
    vLLMService -- Token Stream --> AtomaNode
    AtomaNode -- Stream Response --> ClientScript
    AtomaNode -- Stream Metrics --> PrometheusClient
    AtomaProxy -- Request node registry --> n2["Sui Testnet&nbsp; Contract"]
    n2 -- Respond Atoma Node to process request --> AtomaProxy
    PurchaseScript -- purchase Stack --> AtomaProxy
    AtomaProxy -- purchase stack on-chain txn --> n2
    n2 -- assign nodgebadge --> AtomaNode
    n2 -- assign stack --> AtomaProxy
    ClientScript -- chat completion request --> AtomaProxy
    PrometheusClient -- metrics --> GraphanaDashboard
    ClientScript -- assemble responses --> GithubArtifacts

    n2@{ shape: rect}
```

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
