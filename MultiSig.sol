//SPDX-License-Identifier:MIT

pragma solidity ^0.8.26;

// Custom errors
error NotOwner(address caller);
error InvalidThreshold();
error NotEnoughOwners();
error InvalidId();
error InvalidAddress();
error EmptyTransaction();
error AlreadyApproved();
error ThresholdNotMet();
error TransactionFailed();

contract MultiSig {

    address[] public Owners;
    uint256 public immutable Threshold; // set in constructor, never changes

    // replaced with mapping for lookup instead of looping
    mapping(address => bool) public isOwner;

    constructor(address[] memory _Owners, uint256 _threshold) {
        require(_Owners.length >= 2, NotEnoughOwners());
        require(_threshold >= 2 && _threshold <= _Owners.length, InvalidThreshold());
        
        uint256 len = _Owners.length; 
        for(uint256 i = 0; i < len; i++) {
            Owners.push(_Owners[i]);
            isOwner[_Owners[i]] = true;
        }
        Threshold = _threshold;
    }

    enum States{None, Pending, Executed}

    struct TxDetails {
        address receiver;
        uint256 approvals;
        uint256 amount;
        States _state;
    }
    mapping(uint256 => TxDetails) public Transactions;
    mapping(uint256 => mapping(address => bool)) public hasApproved;

    modifier checkId(uint256 _ID) {
        require(Transactions[_ID]._state == States.Pending, InvalidId());
        _;
    }

    modifier checkOwner() {
        if(!isOwner[msg.sender]) revert NotOwner(msg.sender);
        _;
    }

    event Execute(address to, uint256 _amount, uint256 approvals, States state);

    uint256 IdCount = 1;

    function submitTransaction(address _to, uint256 _amount) checkOwner() public {
        require(_to != address(0), InvalidAddress());
        require(_amount > 0, EmptyTransaction());
        hasApproved[IdCount][msg.sender] = true;
        Transactions[IdCount] = TxDetails(_to, 1, _amount, States.Pending);
        IdCount++;
    }

    function Approve(uint256 _txId) public 
    checkOwner()
    checkId(_txId) {
        require(!hasApproved[_txId][msg.sender], AlreadyApproved());
        hasApproved[_txId][msg.sender] = true;
        Transactions[_txId].approvals++;
    }

    function execute(uint256 _txId) public 
    checkId(_txId) {
        require(Transactions[_txId].approvals >= Threshold, ThresholdNotMet());
        address _to = Transactions[_txId].receiver;
        uint256 Amount = Transactions[_txId].amount;
        uint256 approvals = Transactions[_txId].approvals;
        Transactions[_txId]._state = States.Executed;
        (bool success, ) = _to.call{value:Amount}("");
        require(success, TransactionFailed());

        emit Execute(_to, Amount, approvals, States.Executed);
    }

    receive() external payable{}
}