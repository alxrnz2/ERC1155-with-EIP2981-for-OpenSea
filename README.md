# ERC 1155 with EIP 2981 royalties and OpenSea-specific additions

### Overview

This repo contains [OpenZeppelin's](https://docs.openzeppelin.com/contracts/3.x/erc1155) standard [ERC 1155](https://eips.ethereum.org/EIPS/eip-1155) contracts, slightly modified for:
1) [EIP 2981](https://eips.ethereum.org/EIPS/eip-2981) royalties standard.
2) OpenSea suggested additions like [whitelisting and meta-transactions](https://docs.opensea.io/docs/polygon-basic-integration) to reduce trading friction on Polygon, a `PermanentURI` event to signal frozen metadata, an [ERC 721](https://eips.ethereum.org/EIPS/eip-721)-like token metadata return, and [contract-level metadata](https://docs.opensea.io/docs/contract-level-metadata) that collectively streamline listing.
4) Hard caps on token and edition supply.

### Why use this repo?

You're looking to create a semi-fungible NFT series that's forward-compatible with EIP 2981 and allows for easy OpenSea import.

**Semi-fungible**: ERC 1155's semi-fungible standard refers to a collection that consists of non-fungible tokens, each with multiple fungible editions. For instance, the ParkPics collection featured as an example in this repository includes 14 non-fungible tokens, each of which can be minted up to 10 times in identical (or fungible) editions.

**EIP 2981**: As of January 2022, Ethereum and Polygon NFT royalties are set by exchanges, which makes royalty enforcement challenging. EIP 2981 is a royalty standard that will likely be implemented across NFT exchanges in the near future. The standard's `royaltyInfo` function returns a public address for the intended royalty recipient and a royalty amount in the sale currency. An exchange would query the function with the NFT's `tokenId` and sale price, and then remit royalties accordingly. Note: the royalty payment isn't built into the contract's transfer functions, so we'd still rely on exchanges to certain extent.

**Easy OpenSea import**: If you're looking to list on OpenSea, they recommend a few additions to the OpenZeppelin standard contracts to streamline integration. Whitelisting the OpenSea proxy contract address enables NFT buyers to list on OpenSea without paying gas fees. Meta-transactions via `ContextMixin` enable gasless user transactions. `PermanentURI` signals frozen token metadata to OpenSea. An override of the `uri` function (metadata) ensures OpenSea correctly caches NFT metadata and images without needing to rely on the ERC1155 ID substitution format. Contract-level metadata pre-populates basic information about the collection upon import.

### High-level instructions

1) [**Upload/pin token metadata through a decentralized service**](## 1. Pin/upload token metadata). We used IPFS and Filecoin in this repo via NFT.storage; Arweave is another popular solution.
2) [**Adjust and/or update the smart contracts for your project's needs**]. If you're just looking to test deployment, you can use the contracts in this repo as-is and experiment using the ParkPics metadata and images. Otherwise, adapt the contracts as desired for your project.
3) [**Deploy your contract to a testnet, then mainnet for any EVM blockchain**]. We include steps for Remix (easiest) and Hardhat (most robust), but you can also use Truffle (java-based) or Brownie (python-based) for deployment. You can also mint at this stage through a script, limited to about 150 NFTs per command. We'll also show steps for minting via the block explorer write functions.
4) [**Verify your contract on the applicable block explorer**]. We'll show you how to verify contracts using HardHat, one easy option.
5) [**Import your contract to OpenSea**]. Once your contract is deployed and verified, you can quickly import to OpenSea via [Get Listed](https://opensea.io/get-listed). You just need the contract address, which you can copy from the block explorer. You'll also need to be signed into OpenSea with the contract's owner address before adjusting collection information.

## 1. Pin/upload token metadata

### NFT metadata overview

If you're in this repo, we assume you understand the basics of NFTs and metadata/image pinning/storage. If you're new to content addressing, we recommend these tutorials from ProtoSchool: [Content Addressing](https://proto.school/content-addressing) and [Anatomy of a CID](https://proto.school/anatomy-of-a-cid).

At a high-level, an NFT is simply a ledger entry within a smart contract (or program that runs on blockchain) that allocates ownership of a specific token ID. That smart contract then points to metadata via a `uri` function ([Uniform Resource Indicator](https://en.wikipedia.org/wiki/Uniform_Resource_Identifier)), generally in JSON format, and/or an image for each token ID via a link/pin.

That link could be as simple as a website URL where the data is stored, but then the NFT would be vulnerable to changes made by the domain owner. To ensure the NFT doesn't change over time (unless change is a desired feature), projects generally use content addressing and decentralized file storage. One common combination is [IPFS and Filecoin](https://docs.filecoin.io/about-filecoin/ipfs-and-filecoin/); another is [Arweave](https://www.arweave.org/).

Occasionally, NFT collections include metadata on-chain, but generally storing metadata on blockchains is prohibitively expensive, versus a solution like IPFS/Filecoin.

If you're new to NFT metadata standards, we recommend these guides from [OpenSea](https://docs.opensea.io/docs/metadata-standards) and [NFT School](http://nftschool.dev.ipns.localhost:8080/reference/metadata-schemas/).

And if you're interested in a python script to convert a CSV file to token JSONs, stay tuned for a follow-up repo.

### Recommended tools for pin/upload

For this repo, we used IPFS and Filecoin via two easy tools:
1) **[IPFS CAR generator](http://car.ipfs.io.ipns.localhost:8080/)**: Convert token-level images (likely PNGs) and metadata (JSONs) into CARs. You'll need to upload the images first, so you can use the images' CAR in the token JSONs.
2) **[NFT.Storage for upload](https://nft.storage/)**: Upload CARs to IPFS and Filecoin servers for decentralized pinning and storage, respectively.

This [IPFS CAR generator](http://car.ipfs.io.ipns.localhost:8080/) returns a Content-Addressed Archive (CAR file) with a unique Content Identifier (CID) based on the files uploaded. You can use this tool for your token-level metadata (individual JSONs for each token) and images. For instance, the two ParkPics CARs consist of (1) JSONs numbered `1.json` to `14.json` containing each token's metadata (park, feature, type, image URI, etc.), and (2) PNGs numbered `1.png` to `14.png` with the park pictures themselves.

For this smart contract's `uri` function to work, token metadata needs to be stored in a CAR with directory file names that match each token's ID. For instance, token two's metadata should be stored as `2.json` within the CAR. After uploading the token-level metadata and images (separately), you'll be able to download each CAR file.

Reminder: Start with the images, because image pins need to be added to the JSON files before you can generate the metadata CAR.

<img width="740" alt="image" src="https://user-images.githubusercontent.com/36116381/149631861-9a75babf-c590-4b1e-a8a8-16c124cbce71.png">

Once you have the image and metadata CARs, you can use [NFT.Storage](https://nft.storage/), a free service provided by Protocol Labs, to upload those CARs to Filecoin and IPFS servers (see below).

<img width="865" alt="image" src="https://user-images.githubusercontent.com/36116381/149632270-4cd49ffc-1955-4d94-9de9-53ebfc6de2bc.png">

After uploading via NFT.Storage, you'll be able to view your metadata via the IPFS pins. There may be a slight delay, so give the network at least a few minutes to process your CAR uploads before trying to retrieve files.

Using [Brave](https://brave.com/), a browser that natively integrates IPFS, you can access IPFS via `ipfs://<CAR pin>/<file>`. For instance, ParkPics token one metadata is available via `ipfs://bafybeigpo7cmcfkicsee3redrzcwzqsnywvyjehvam4mim3v7ng65titby/1.json` in Brave. Using a web browser without IPFS integrated, you can access the same metadata via `https://bafybeigpo7cmcfkicsee3redrzcwzqsnywvyjehvam4mim3v7ng65titby.ipfs.dweb.link/1.json`.

<img width="952" alt="image" src="https://user-images.githubusercontent.com/36116381/149633191-acb52033-5d92-4a0e-9371-18f82fc74969.png">

Then, using the same retrieval approach in Brave, you can access the token's image via `ipfs://bafybeiatmiig6ylhha5p7o7bxvqutfitv6k2n5ghche4r22tgkmoz6gu5u/1.png`, as provided in the JSON's `image` field (see above).

<img width="959" alt="image" src="https://user-images.githubusercontent.com/36116381/149633212-f3dde4f9-e377-429b-90e3-edb7eb1840c2.png">

To display images and metadata for NFTs, services like OpenSea retrieve and cache that data following these same steps, albeit less manually.

Note: There are many other ways to pin/upload metadata and images to IPFS and Arweave. And to the extent you don't want to use CARs, you'll need to adjust the smart contracts' `uri` function and `PermanentURI` events accordingly.

## 2. Create smart contracts

### OpenZeppelin Wizard

We started with the [OpenZeppelin Wizard](https://docs.openzeppelin.com/contracts/4.x/wizard) to create the base ERC 1155 contracts.
* **Functions**: Mintable and Pausable (allows for owner minting and contract pausing, in the extent something goes wrong)
* **Access Control**: Ownable (one account can mint, pause, etc., versus segregated permissions for multiple accounts)

If you'd like to change these presets, it's probably easiest to start with the [OpenZeppelin Wizard](https://docs.openzeppelin.com/contracts/4.x/wizard), download your new contracts, and then manually incorporate EIP 2981 royalties and the OpenSea-specific changes, as documented below.

<img width="368" alt="image" src="https://user-images.githubusercontent.com/36116381/149416526-95de8b9b-e49e-4f8e-9b7a-25c2c6984c2e.png">

### EIP 2981 royalties

EIP 2981 includes two key functions: `royaltyInfo` and `supportsInterface`. In addition to those functions, we implemented the ability to change the royalty recipient. To remove that flexibility, replace `_recipient` with the desired recipient public address.

All EIP 2981 required functions were implemented in the token contract, [`ParkPics.sol`](contracts/ParkPics.sol) in this example.

**Import the EIP 2981 interface in `ParkPics.sol`**:
```
import "./@openzeppelin/contracts/interfaces/IERC2981.sol";
```

The best practice with any standard implementation is to start with an interface. The `IERC2981.sol` `royaltyInfo` function is then overriden in `ParkPics.sol` (see below).

**`royaltyInfo` function in `ParkPics.sol`**:
```
function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
        return (_recipient, (_salePrice * 1000) / 10000);
}
```

When called, this function returns royalty recipient and amount, indifferent as to sale currency. We set royalties at 10% or 1,000 basis points; to set a different percentage, just adjust the `1000` to your desired royalty in basis points.

Note: royalties are not built into the contract's `transfer` functions, which do not have an input for sales price. Instead, the NFT owner delegates the ability to transfer to NFT exchanges via the `setApprovalForAll` function in `ERC1155.sol`, then the exchange initiates a (1) token transfer once the listing price is fulfilled and (2) royalty payout, which is currently based on information provided to each exchange by the collection creator (for OpenSea, the contract owner needs to populate royalty recipient and amount manually on their site when updating collection information).

Reputable exchanges tend to follow community standards, which we expect EIP 2981 to become in the near future. Thus, we're including these functions for forward compatibility, even if most exchanges don't follow EIP 2981 today (January 2022).

**supportsInterface override in `ParkPics.sol`**:
```
function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, IERC165) returns (bool) {
        return (interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId));
}
```

This function signals that the contract is compatible with EIP 2981, in addition to ERC 1155 and ERC 165 (via `super`).

**Maintain flexibilty to change royalty recipient in `ParkPics.sol`**:
```
address private _recipient;
...
constructor() ERC1155("") {
        ...
        _recipient = owner();
}
...
function _setRoyalties(address newRecipient) internal {
        require(newRecipient != address(0), "Royalties: new recipient is the zero address");
        _recipient = newRecipient;
}
...
function setRoyalties(address newRecipient) external onlyOwner {
        _setRoyalties(newRecipient);
}
```

These additions create a private varible for royalty recipient address, define that address as the contract owner upon deployment in the constructor, and create an `onlyOwner` function to update that recipient address in the future. If you don't need this flexibility, feel free to delete the variable, constructor definition, and `setRoyalties` functions, and replace `_recipient` in the `royaltyInfo` function with a static public address for the desired recipient.

### OpenSea-specific changes

These OpenSea additions enable whitelisting, meta-transactions, a permanent metadata event, token metadata override, and contract-level metadata. Some of these additions may be redundant given recent OpenSea infrastructure changes, but to cover all bases, we pieced together and implemented each per OpenSea's developer docs.

These changes were implemented in [`ParkPics.sol`](contracts/ParkPics.sol) and [`ERC1155.sol`](contracts/@openzeppelin/contracts/token/ERC1155/ERC1155.sol).

**Whitelisting in `ERC1155.sol`**:
```
function isApprovedForAll(...) ... (...) {
        /** @dev OpenSea whitelisting. */
        if(operator == address(0x207Fa8Df3a17D96Ca7EA4f2893fcdCb78a304101)){
            return true;
        }
        /** @dev Standard ERC1155 approvals. */ 
        return _operatorApprovals[account][operator];
}
```

The `if` addition above automatically approves a token owner's listing on OpenSea without requiring the owner to pay gas fees for the approval transaction. If you'd like to add additional marketplace addresses, you can use the `||` operator ("or" operator in Solidity) to add those marketplace addresses to the `if` statement.

**Meta-transactions in `ParkPics.sol` via import of `ContextMixin.sol`**:
```
import "./@openzeppelin/contracts/utils/ContextMixin.sol";
...
function _msgSender() internal override view returns (address) {
        return ContextMixin.msgSender();
}
```

After adding `ContextMixin.sol` to `contract/utils`, we import that contract to the token contract and add a function to override `_msgSender`. Learn more from [OpenSea](https://docs.opensea.io/docs/polygon-basic-integration) about gas-less transactions.

**Token metadata pin and `PermanentURI` event in `ERC1155.sol`**:
```
import "../../utils/Strings.sol";
...
using Strings for uint256;
string internal _uriBase;
event PermanentURI(string _value, uint256 indexed _id);
...
constructor(string memory uri_) {
        ...
        // Set metadata pin for uri override and permanentURI events
        _uriBase = "ipfs://bafybeicvbipj7n6zkphi7u5tu4gmu7oubi7nt5s2fjvkzxn7ggr4fjv2jy/"; // IPFS base for ParkPics collection
        ...
}
...
function _mint(...) ... {
        ...
        // Signals frozen metadata to OpenSea
        emit PermanentURI(string(abi.encodePacked(_uriBase, Strings.toString(id), ".json")), id);
        ...
}
...
function _mintBatch(...) ... {
        ...
        for (uint256 i = 0; i < ids.length; i++) {
            ...
            // Signals frozen metadata for OpenSea
            emit PermanentURI(string(abi.encodePacked(_uriBase, Strings.toString(ids[i]), ".json")), ids[i]);
        }
        ...
}
```

OpenSea looks for a `PermanentURI` event to determine if a token's metadata is frozen. The event simply emits the URI for each token as they're minted. Since we also need to return the URI in the token contract, `ParkPics.sol`, we define `_uriBase` as an internal variable that can be called in the token contract `uri` function.

Learn more [here](https://docs.opensea.io/docs/metadata-standards).

**Token metadata return override in `ParkPics.sol`**:
```
function uri(uint256 tokenId) override public view returns (string memory) {
        ...
        return string(abi.encodePacked(_uriBase, Strings.toString(tokenId), ".json"));
}
```

Rather than relying on marketplaces to support the ERC 1155 [ID substitution method](https://docs.openzeppelin.com/contracts/3.x/api/token/erc1155#IERC1155MetadataURI) for token metadata, we overrode the function to return an IPFS pin for the token's applicable JSON file. For our function to work properly, metadata needs to be stored in a Content-Addressed Archive (CAR). Use this [tool](http://car.ipfs.io.ipns.localhost:8080/) to convert metadata into CARs for upload.

**Contract-level metadata in `ParkPics.sol`**:
```
string public name;
string public symbol;
...
constructor() ERC1155("") {
        name = "Park Pics";
        symbol = "PPS";
        ...
}
...
function contractURI() public pure returns (string memory) {
        return "ipfs://bafkreigpykz4r3z37nw7bfqh7wvly4ann7woll3eg5256d2i5huc5wrrdq"; // Contract-level metadata for ParkPics
}
```

Upon importing the contract to OpenSea, contract-level metadata will now pre-populate in the applicable collection fields.

### Hard caps on token supply and editions

Hard caps were implemented in [`ParkPics.sol`](contracts/ParkPics.sol) and [`ERC1155.sol`](contracts/@openzeppelin/contracts/token/ERC1155/ERC1155.sol).

**Token hard cap in `ParkPics.sol`**:
```
constructor() ERC1155("") {
        ...
        total_supply = 14;
        ...
}
...
function uri(...) ... (...) {
        // Tokens minted above the supply cap will not have associated metadata.
        require(tokenId >= 1 && tokenId <= total_supply, "ERC1155Metadata: URI query for nonexistent token");
        ...
}
```

Our `require` function effectively limits the total token supply by blocking metadata retrieval above the token hard cap (token 14 for ParkPics). Alternatively, we could implement this limit through the mint functions via additional `require` functions, similar to the editions caps below.

**Edition hard cap in `ERC1155.sol`**:
```
// Mapping from token ID to global token editions and global limit
mapping(uint256 => uint256) private _globalEditions;
uint256 private _editionLimit;
...
constructor(...) {
        ...
        // Set maximum editions per token
        _editionLimit = 10;
}
...
function _mint(...) ... {
        ...
        // Caps per token supply to 10 editions
        require((_globalEditions[id] + amount) <= _editionLimit, "ERC1155: exceeded token maximum editions");
        ...
        // Tracks number of editions per token
        _globalEditions[id] += amount;
        ...
} 
...
function _mintBatch(...) ... {
        ...
        for (uint256 i = 0; i < ids.length; i++) {
            // Caps per token supply to 10 editions
            require((_globalEditions[ids[i]] + amounts[i]) <= _editionLimit, "ERC1155: exceeded token maximum editions");
            ...
            // Tracks number of editions per token
            _globalEditions[ids[i]] += amounts[i];
            ...
        }
    ...
}
```

Each time a new NFT is minted, the edition counter is updated. In this sample collection, those editions are capped at 10 each in the constructor, after which the mint functions throw errors. As mentioned above, a token supply limit could be implemented in a similar manner through these mint functions.

### Other contract notes

* **Minting factory**: We did not include a minting factory in this repo. All tokens are minted by the owner and then transfered or listed for sale by the owner. An additional factory contract would be required to enable minting at a set price or through an auction.
* **OpenSea additions and hard caps**: If you don't need the OpenSea additions and/or token/edition hard caps, we recommend starting with the [OpenZeppelin Wizard](https://docs.openzeppelin.com/contracts/4.x/wizard) and then implementing EIP 2918 royalties per the above steps.

### Changes required to use these contracts for a different collection

**In the token contract (`ParkPics.sol`, to be renamed)**:
1) Change `ParkPics.sol` file name (not strictly required, but recommended).
2) Change `ParkPics` contract name (also not strictly required, but recommended).
3) In the constructor, update `name`, `symbol` and `total_supply`. If you're looking to maintain flexibility to expand token count in the future, remove `total_supply` in the constructor and from the `uri` function.
4) In the `contractURI` function, change the pin to your collection-level metadata. You can remove this function, if not needed, without impacting other functions in the contracts.

**In `ERC1155.sol`**:
1) In the constructor, update `_uriBase` for your token-level metadata CAR.
2) In the constructor, update `_editionLimit` for your desired editions cap. Like token hard caps, you can eliminate edition caps by removing the additional `require` hooks in the mint functions (see above).

## 3. Deploy smart contracts

Once you've refined your smart contracts, save them in a subfolder/directory `contracts` within the folder/directory you're using for deployment. It's best practice, and Hardhat will specifically look for a `contracts` subdirectory when compiling contracts.

To the extent you reorganize the `contracts` subdirectories from this repo, be sure to also update the `import` calls in each contract accordingly.

<img width="263" alt="image" src="https://user-images.githubusercontent.com/36116381/149635193-c892afb3-162d-4e68-a667-abdd8006513d.png">

To execute the commands below on a windows machine, we generally use a [Git Bash](https://git-scm.com/downloads) [terminal](https://code.visualstudio.com/docs/editor/integrated-terminal) in [VS Code](https://code.visualstudio.com/), but there are plenty of other options.

### Deploy with Remix IDE (easiest)

Remix IDE is a web-based development environment designed for Solidity smart contracts. You can easily connect web wallets to Remix and deploy contracts without adding private keys to a config file, etc., which also allows for easy deployment from a hardware wallet that's connected through your web wallet (like [Ledger via MetaMask](https://www.ledger.com/academy/security/the-safest-way-to-use-metamask). For security purposes, we recommend this approach.

When you open [Remix](https://remix.ethereum.org/), you'll see a sample workspace with some simple, sample smart contracts. While there are a few ways to upload your updated smart contracts, we'll use `-connect to localhost-` via `remixd` from the workspace dropdown menu. Find a detailed tutorial for `remixd` [here](https://remix-ide.readthedocs.io/en/latest/remixd.html), and summarized below.

<img width="956" alt="image" src="https://user-images.githubusercontent.com/36116381/149635085-9c92e8ec-dca8-40f8-89c9-7bd0fd7f0e80.png">

**Install Remixd to connect Remix to your local computer**

First, you'll need `npm` and `node`. Follow these [steps](https://docs.npmjs.com/downloading-and-installing-node-js-and-npm) if not already installed. On your desktop, we recommend opening the folder containing subfolder `contracts` in an IDE like VS Code. (Not strictly required, but it'll make it easier to verify your contracts via Hardhat later.)

Once you've installed `npm` and `node`, install `remixd` via a VS Code terminal like [Git Bash](https://git-scm.com/downloads) or through another command line interface (CLI).

```
npm install -g @remix-project/remixd
```

Then, enter the following command to connect to Remix, substituting `<absolute-path>` with the `contracts` folder path. If using Git Bash, refer to this [article](https://opensource.com/article/19/8/understanding-file-paths-linux) to troubleshoot path issues.

```
remixd -s <absolute-path> --remix-ide https://remix.ethereum.org
```

**Deploy smart contracts in Remix**

Returning to Remix in your web brower, select `-connect to localhost-` and `Continue`. You should now be able to see files in your `contracts` folder in Remix. Find detailed steps to compile and deploy smart contracts through Remix [here](https://remix-ide.readthedocs.io/en/latest/create_deploy.html#), and summarized below.

First, select the token contract (`ParkPics.sol` in our sample contracts) in the `File Explorer` tab. Then, in the `Solidity Compiler` tab, select a compiler version at least as recent as that specified in the contracts (0.8.2 per `pragma solidity ^0.8.2;` at the top of `ParkPics.sol`) and click `Compile...`. Finally, in the `Deploy & Run Transactions` tab, select your environment and owner wallet (see below), and deploy the token contract.

To test integration with OpenSea, we recommend using `Injected Web3` for the environment and connecting your web wallet like MetaMask. You can connect to Remix much like other web3 services by signing a transaction with your wallet. In your web wallet, select the desired network for deployment; we recommend trying a testnet first like Rinkeby for Ethereum or Mumbai for Polygon. You'll also need some Ether or Matic in your wallet to cover gas fees for deployment.

Note: If you don't already have Polygon integrated with your web wallet, follow these [steps](https://docs.polygon.technology/docs/develop/metamask/config-polygon-on-metamask/) released by the Polygon team. For testnet transactions, use these faucets for testnet Ether and Matic, respectively: [Rinkeby](https://faucets.chain.link/rinkeby) and [Mumbai](https://faucet.polygon.technology/).

Once you've configured environment and your wallet, click `Deploy` in Remix. You should see a contract address that will enable you to track contract transactions in a block explorer: [Etherscan](https://etherscan.io/) or [Polygonscan](https://polygonscan.com/).

See steps below for easy contract verification through HardHat, which will enable read/write calls from the explorer itself.

### Deploy with Hardhat (recommended)

Find detailed Hardhat instructions [here](https://hardhat.org/getting-started/), and key steps summarized below.

First, install Hardhat and a few key packages (waffle and ethers).

```
npm install --save-dev hardhat
npm install --save-dev @nomiclabs/hardhat-waffle ethereum-waffle chai
npm install --save-dev @nomiclabs/hardhat-ethers ethers
```

Set your directory via `cd` to the folder containing `contracts`. You should see a config file called `hardhat.config.js`. Before compiling your contracts, update the compiler version to at least `solidity: "0.8.2"` for these contracts. (You can find a sample config file in this repo with some required fields added.)

Using Hardhat, compile your smart contracts. This will create artifacts, ABI, and bytecode for deployment and verification.

```
npx hardhat compile
```

Before deployment, you'll need to update the config file with an API key and private key (server and wallet, respectively) for each blockchain you plan to use. We have placeholders for Mumbai, Polygon, Rinkeby, and Ethereum.
* For servers, [Infura](https://infura.io/) and [Alchemy](https://www.alchemy.com/) are two popular options through which you can get started for free. We set the sample config file to Infura, just waiting for your API key.
* For a wallet, you'll just need your private key (see steps [here](https://metamask.zendesk.com/hc/en-us/articles/360015289632-How-to-Export-an-Account-Private-Key) to export from MetaMask). Paste the private key into the config file's `accounts` field for each applicable blockchain.

Next, you'll need a `.js` script to deploy your contract. We included a simple sample script for `ParkPics.sol` in this repo that you can modify accordingly. Save your script in the main directory and run the command below. Replace `<NETWORK>` with your desired blockchain, consistent with the spelling/case of the labels in your config file.

You'll also want to add `require("@nomiclabs/hardhat-waffle");` (which implicitly adds `require("@nomiclabs/hardhat-ethers");`) to your config file. Learn more about the Waffle library from the [Hardhat](https://hardhat.org/guides/waffle-testing.html) and [Waffle](https://ethereum-waffle.readthedocs.io/en/latest/index.html) teams.

```
npx hardhat run ./scripts/deployMint.js --network <NETWORK>

Example for Mumbai testnet using our sample config file:
npx hardhat run ./scripts/deployMint.js --network mumbai
```

That's it. You've deployed your contract using Hardhat. You should see a contract address that you can use in a block explorer to monitor transactions.

## 4. Verify smart contracts with Hardhat

Once you deploy your smart contracts, you should verify them with the applicable block explorer to enable read/write interactions from that explorer.

If you deployed the contracts in Remix, you'll just need to follow the Hardhat steps above through compilation to use Hardhat for verification. (No need to deploy via Hardhat, but you'll need the artifacts, ABI, and bytecode.)

Before verifying through Hardhat, you need to add an API key for Etherscan or Polygonscan (easy to set up when you create an account), and `require("@nomiclabs/hardhat-etherscan");` to your config file. (See the sample config file by way of example.)

Install the etherscan package and then run the Hardhat verify command, replacing `<NETWORK>` with the applicable blockchain and `<CONTRACT>` with the deployed contract's address.

```
npm install --save-dev @nomiclabs/hardhat-etherscan
npx hardhat verify --network <NETWORK> <CONTRACT>
```

Once you receive a success message, you should be able to view your contracts and their read/write functions on the applicable block explorer. If you connect a web wallet that contains the contract's owner account, you'll be able to execute `onlyOwner` write transactions (like minting) from the explorer.

## 5. Import collection to OpenSea

With your contracts deployed and verified, you're ready to import the collection to OpenSea. First, navigate to OpenSea's [Get Listed page](https://opensea.io/get-listed). Select the appropriate testnet or mainnet supported by OpenSea (again, we recommend testnet deployment/import before mainnet).

<img width="940" alt="image" src="https://user-images.githubusercontent.com/36116381/149671990-f03262dc-71c8-41a3-8b1a-a01d4623bc8c.png">

Enter the contract address and OpenSea will import your collection.

<img width="940" alt="image" src="https://user-images.githubusercontent.com/36116381/149672146-714e78ba-e3fe-494a-ad55-d0191f07995e.png">

If you sign into OpenSea with the contract's owner address, you'll be able to update collection information. To the extent you included a `contractURI` function, some collection details should already be populated. Since OpenSea doesn't support EIP 2981, as of January 2022, you'll need to manually enter royalty information.

Note: It often takes OpenSea 24 to 48 hours to cache all the metadata for minted NFTs in your collection and then add metadata filter fields.
