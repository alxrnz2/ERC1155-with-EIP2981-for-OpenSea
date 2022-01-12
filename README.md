# ERC1155 with EIP2981 royalties

**Overview**

This repo contains [OpenZeppelin's](https://docs.openzeppelin.com/contracts/3.x/erc1155) standard [ERC 1155](https://eips.ethereum.org/EIPS/eip-1155) contracts, slightly modified with the [EIP 2981](https://eips.ethereum.org/EIPS/eip-2981) royalties standard and additions for OpenSea like [whitelisting and meta-transactions](https://docs.opensea.io/docs/polygon-basic-integration) to reduce trading friction on Polygon, an [ERC 721](https://eips.ethereum.org/EIPS/eip-721)-like URI function, [contract-level metadata](https://docs.opensea.io/docs/contract-level-metadata) to streamline collection listing.

**Why use this repository?**

You're looking to create a semi-fungible NFT series that's forward-compatible with EIP 2981 and allows for easy OpenSea import. Semi-fungible refers to a collection that consists of non-fungible tokens with multiple fungible editions. For instance, the ParkPics collection featured in the repository includes 14 non-fungible tokens, each of which can be minted up to 10 times in identical (or fungible) editions.

## Contract methodology

**OpenZeppelin Wizard**

We started with the [OpenZeppelin Wizard](https://docs.openzeppelin.com/contracts/4.x/wizard) to create the base ERC1155 contracts.
* **Functions**: Mintable and Pausable (allows for owner minting and contract pausing to the extent something goes wrong)
* **Access Control**: Ownable (one account can mint, pause, etc., versus segregated permissions for multiple accounts)

If you'd like to change these presets, it's probably easiest to start with the [OpenZeppelin Wizard](https://docs.openzeppelin.com/contracts/4.x/wizard), then manually incorporate EIP 2981 royalties and the OpenSea-specific changes documented below in this **Contract methology** section.

**EIP2918 royalties implementation**

*Coming soon*

**OpenSea-specific changes**

*Coming soon*

## Deploy with Remix

*Coming soon*

## Deploy with HardHat

*Coming soon*
