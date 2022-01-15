# ERC1155 with EIP2981 royalties and OpenSea-specific additions

### Overview

This repo contains [OpenZeppelin's](https://docs.openzeppelin.com/contracts/3.x/erc1155) standard [ERC 1155](https://eips.ethereum.org/EIPS/eip-1155) contracts, slightly modified for:
1) [EIP 2981](https://eips.ethereum.org/EIPS/eip-2981) royalties standard.
2) OpenSea suggested additions like [whitelisting and meta-transactions](https://docs.opensea.io/docs/polygon-basic-integration) to reduce trading friction on Polygon, a `PermanentURI` event to signal frozen metadata, an [ERC 721](https://eips.ethereum.org/EIPS/eip-721)-like token metadata return, and [contract-level metadata](https://docs.opensea.io/docs/contract-level-metadata) that collectively streamline listing.
4) Hard caps on token and edition supply.

### Why use this repo?

You're looking to create a semi-fungible NFT series that's forward-compatible with EIP 2981 and allows for easy OpenSea import.

**Semi-fungible**: ERC 1155's semi-fungible standard refers to a collection that consists of non-fungible tokens, each with multiple fungible editions. For instance, the ParkPics collection featured as an example in this repository includes 14 non-fungible tokens, each of which can be minted up to 10 times in identical (or fungible) editions.

**EIP 2981**: As of January 2022, Ethereum and Polygon NFT royalties are set by exchanges, which makes royalty enforcement challenging. EIP 2981 is a royalty standard that will likely be implemented across NFT exchanges in the near future. The standard's `royaltyInfo` function returns a public address for the intended royalty recipient and a royalty amount in the sale currency. An exchange would query the function with the NFT's `tokenId` and sale price, and then remit royalties accordingly. Note: the royalty payment isn't built into the contract's transfer functions, so we'd still rely on exchanges to certain extent.

**Easy OpenSea import**: If you're looking to list on OpenSea, they recommend a few additions to the OpenZeppelin standard contracts to streamline integration. Whitelisting the OpenSea proxy contract address enables NFT buyers to list on OpenSea without paying gas fees. Meta-transactions via `ContextMixin` enable gasless user transactions. `PermanentURI` signals forzen token metadata to OpenSea. An override of the `uri` function (metadata) ensures OpenSea correctly caches NFT metadata and images without needing to rely on the standard ERC1155 ID substitution format. Contract-level metadata pre-populates basic information about the collection upon import.

### High-level instructions

1) **Upload/pin token metadata through a decentralized service**. We used IPFS and Filecoin in this repo via NFT.storage; Arweave is another popular solution.
2) **Adjust and/or update the smart contracts for your project's needs**. If you're just looking to test deployment, you can use the contracts in this repo as-is and experiment using the ParkPics metadata and images. Otherwise, adapt the contracts as you see fit for your project.
3) **Deploy your contract to a testnet, then mainnet for any EVM blockchain**. We'll explain steps for Remix (easiest) and Hardhat (most robust), but you can also use Truffle (java-based) or Brownie (python-based) for deployment. You can also mint at this stage through a script, limited to about 150 NFTs per command. We'll also show steps for minting via the block explorer write functions.
4) **Verify your contract on the applicable block explorer**. We'll show you how to verify contracts using HardHat, one easy option for verification.
5) **Import your contract to OpenSea**. Once your contract is deployed and verified, you can quickly import to OpenSea via [Get Listed](https://opensea.io/get-listed). You just need the contract address, which you can copy from the block explorer. You'll also need to sign into OpenSea with the contract's owner address before adjusting collection information.

## 1. Pin/upload token metadata

*Coming soon.*

## 2. Create smart contracts

### OpenZeppelin Wizard

We started with the [OpenZeppelin Wizard](https://docs.openzeppelin.com/contracts/4.x/wizard) to create the base ERC1155 contracts.
* **Functions**: Mintable and Pausable (allows for owner minting and contract pausing, in the extent something goes wrong)
* **Access Control**: Ownable (one account can mint, pause, etc., versus segregated permissions for multiple accounts)

If you'd like to change these presets, it's probably easiest to start with the [OpenZeppelin Wizard](https://docs.openzeppelin.com/contracts/4.x/wizard), download your new contracts, and then manually incorporate EIP 2981 royalties and the OpenSea-specific changes, as documented below.

<img width="368" alt="image" src="https://user-images.githubusercontent.com/36116381/149416526-95de8b9b-e49e-4f8e-9b7a-25c2c6984c2e.png">

### EIP 2981 royalties

EIP 2981 includes two key functions: `royaltyInfo` and `supportsInterface`. In addition to those functions, we implemented the ability to change the royalty recipient. To remove that flexibility, replace `_recipient` with the desired recipient public address.

All EIP 2981 required functions were implemented in the token contract, `ParkPics.sol` in this example.

**Import the EIP 2981 interface in `ParkPics.sol`**:
```
import "./@openzeppelin/contracts/interfaces/IERC2981.sol";
```

The best practice with any standard implementation is to start with an interface. The `IERC2981.sol` `royaltyInfo` function is then overriden in `ParkPics.sol` (see below).

**`royaltyInfo` function in `ParkPics.sol`**:
```
function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (_recipient, (_salePrice * 1000) / 10000);
    }
```

When called, this function returns royalty recipient and amount, indifferent as to sale currency. We set royalties at 10% or 1,000 basis points; to set a different percentage, just adjust the `1000` to your desired royalty in basis points.

Note: royalties are not built into the contract's `transfer` functions, which do not have an input for sales price. Instead, the NFT owner delegates the ability to transfer to NFT exchanges via the `setApprovalForAll` function in `ERC1155.sol`, then the exchange initiates a (1) token transfer once the listing price is fulfilled and (2) royalty payout, which is currently based on information provided to each exchange by the collection creator (for OpenSea, the contract owner needs to populate royalty recipient and amount manually on their site when updating collection information).

Reputable exchanges tend to follow community standards, which we expect EIP 2981 to become in the near future. Thus, we're including these functions for forward compatibility, even if most exchanges don't follow EIP 2981 today (January 2022).

**supportsInterface override in `ParkPics.sol`**:
```
function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, IERC165)
        returns (bool)
    {
        return (
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId)
        );
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

OpenSea looks for a `PermanentURI` event to determine if a token's metadata is frozen. The event simply emits the URI for each token as they're minted. Learn more [here](https://docs.opensea.io/docs/metadata-standards).

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

### Deploy with Remix

*Coming soon*

### Deploy with HardHat

*Coming soon*

## 4. Verify smart contracts

*Coming soon*

## 5. Import collection to OpenSea

*Coming soon*
