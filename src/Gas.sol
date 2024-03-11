// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.8;

contract GasContract {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public whitelist;
    mapping(address => ImportantStruct) public whiteListStruct;
    address private _owner;

    address[5] public administrators;

    struct ImportantStruct {
        uint256 amount;
        bool paymentStatus;
    }

    event AddedToWhitelist(address userAddress, uint256 tier);
    event WhiteListTransfer(address indexed);

    modifier hasEnoughBalance(uint256 _amount) {
        if (_amount > balances[msg.sender]) {
            revert();
        }

        _;
    }

    constructor(address[] memory _admins, uint256 _totalSupply) {
        if (_admins.length > 5) {
            revert();
        }

        _owner = msg.sender;

        for (uint256 ii; ii < _admins.length; ii++) {
            administrators[ii] = _admins[ii];
        }

        balances[_owner] = _totalSupply;
    }

    function checkForAdmin(address _user) public view returns (bool admin_) {
        for (uint256 ii; ii < administrators.length; ii++) {
            if (administrators[ii] == _user) {
                return true;
            }
        }
    }

    function balanceOf(address _user) public view returns (uint256 balance_) {
        return balances[_user];
    }

    function getTradingMode() public pure returns (bool mode_) {
        return true;
    }

    function transfer(
        address _recipient,
        uint256 _amount,
        string calldata _name
    ) public hasEnoughBalance(_amount) {
        if (bytes(_name).length > 8) {
            revert();
        }

        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;
    }

    function addToWhitelist(address _userAddrs, uint256 _tier) public {
        if (!checkForAdmin(msg.sender) || msg.sender != _owner) {
            revert();
        }

        if (_tier > 254) {
            revert();
        }

        whitelist[_userAddrs] = _tier < 3 ? _tier : 3;

        emit AddedToWhitelist(_userAddrs, _tier);
    }

    function whiteTransfer(
        address _recipient,
        uint256 _amount
    ) public hasEnoughBalance(_amount) {
        uint256 usersTier = whitelist[msg.sender];
        if (usersTier == 0 || usersTier > 4) {
            revert();
        }

        if (_amount < 4) {
            revert();
        }

        whiteListStruct[msg.sender].amount = _amount;
        whiteListStruct[msg.sender].paymentStatus = true;

        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;
        balances[msg.sender] += whitelist[msg.sender];
        balances[_recipient] -= whitelist[msg.sender];

        emit WhiteListTransfer(_recipient);
    }

    function getPaymentStatus(
        address sender
    ) public view returns (bool, uint256) {
        return (
            whiteListStruct[sender].paymentStatus,
            whiteListStruct[sender].amount
        );
    }

    receive() external payable {
        payable(msg.sender).transfer(msg.value);
    }

    fallback() external payable {
        payable(msg.sender).transfer(msg.value);
    }
}
