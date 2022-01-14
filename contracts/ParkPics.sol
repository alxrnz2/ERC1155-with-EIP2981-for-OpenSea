// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./@openzeppelin/contracts/interfaces/IERC2981.sol";
import "./@openzeppelin/contracts/access/Ownable.sol";
import "./@openzeppelin/contracts/security/Pausable.sol";
import "./@openzeppelin/contracts/utils/Strings.sol";
import "./@openzeppelin/contracts/utils/ContextMixin.sol";

/// @custom:security-contact <security email address>
contract ParkPics is ERC1155, IERC2981, Ownable, Pausable, ContextMixin {

    using Strings for uint256;
    string public name;
    string public symbol;
    uint256 public total_supply;
    address private _recipient;

    constructor() ERC1155("") {
        name = "Park Pics";
        symbol = "PPS";
        total_supply = 14;
        _recipient = owner();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /** @dev URI override for OpenSea traits compatibility. */

    function uri(uint256 tokenId) override public view returns (string memory) {
        // Tokens minted above the supply cap will not have associated metadata.
        require(tokenId >= 1 && tokenId <= total_supply, "ERC1155Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(_uriBase, Strings.toString(tokenId), ".json"));
    }

    /** @dev EIP2981 royalties implementation. */

    // Maintain flexibility to modify royalties recipient (could also add basis points).
    function _setRoyalties(address newRecipient) internal {
        require(newRecipient != address(0), "Royalties: new recipient is the zero address");
        _recipient = newRecipient;
    }

    function setRoyalties(address newRecipient) external onlyOwner {
        _setRoyalties(newRecipient);
    }

    // EIP2981 standard royalties return.
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (_recipient, (_salePrice * 1000) / 10000);
    }

    // EIP2981 standard Interface return. Adds to ERC1155 and ERC165 Interface returns.
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

    /** @dev Meta-transactions override for OpenSea. */

    function _msgSender() internal override view returns (address) {
        return ContextMixin.msgSender();
    }

    /** @dev Contract-level metadata for OpenSea. */

    // Update for collection-specific metadata.
    function contractURI() public pure returns (string memory) {
        return "ipfs://bafkreigpykz4r3z37nw7bfqh7wvly4ann7woll3eg5256d2i5huc5wrrdq"; // Contract-level metadata for ParkPics
    }
}