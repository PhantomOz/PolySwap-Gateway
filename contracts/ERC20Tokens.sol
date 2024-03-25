// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Token is ERC20 {
    error NotOwner();
    error AddressCantBeZeroAddress();

    mapping(address => bool) private s_owners;

    modifier onlyOwner() {
        if (!s_owners[msg.sender]) {
            revert NotOwner();
        }
        _;
    }

    modifier isZeroAddress(address _address) {
        if (_address == address(0)) {
            revert AddressCantBeZeroAddress();
        }
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply
    ) ERC20(_name, _symbol) {
        _mint(msg.sender, _totalSupply);
        s_owners[msg.sender] = true;
    }

    function mint(
        address _to,
        uint256 _amount
    ) external onlyOwner isZeroAddress(_to) {
        _mint(_to, _amount);
    }

    function burn(
        address _from,
        uint256 _amount
    ) external onlyOwner isZeroAddress(_from) {
        _burn(_from, _amount);
    }

    function addOwners(
        address _owner
    ) external onlyOwner isZeroAddress(_owner) {
        s_owners[_owner] = true;
    }
}
