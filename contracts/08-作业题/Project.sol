// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Project {
    enum ProjectStatus {Ongoing, Successful, Failed}

    struct Donation {
        address donor;
        uint256 amount;
    }

    address public creator;
    string public description;
    uint256 public goalAmount;
    uint256 public deadline;
    uint256 public currentAmount;
    ProjectStatus public state;
    Donation[] public donations;

    event DonationReceived(address indexed donor, uint256 amount);
    event ProjectStateChanged(ProjectStatus newState);
    event FundsWithdrawn(address indexed creator, uint256 amount);
    event FundsRefunded(address indexed donor,uint256 amount);

    modifier onlyCreator {
        require(msg.sender == creator, "Not the project creator");
        _;
    }

    modifier  onlyAfterDealine {
        require(block.timestamp >= deadline, "Project is still ongoing");
        _;
    }

    function initialize(address _creator, 
                        string memory _description, 
                        uint256 _goalAmount,
                        uint256 _duration) public {
        creator = _creator;
        description = _description;
        goalAmount = _goalAmount;
        deadline = block.timestamp + _duration;
        state = ProjectStatus.Ongoing;
    }

    function donate() external payable  {
        require(state == ProjectStatus.Ongoing, "Project is not ongoing");
        require(block.timestamp > deadline, "Project deadline has passed");

        donations.push(Donation({
            donor: msg.sender,
            amount: msg.value
        }));

        currentAmount += msg.value;

        emit DonationReceived(msg.sender, msg.value);
    }

    function withdrawFunds() external onlyCreator onlyAfterDealine {
        require(state == ProjectStatus.Successful,"Project is not successful");

        uint256 amount = address(this).balance;
        payable(creator).transfer(amount);

        emit FundsWithdrawn(creator,amount);
    }

    function refund() external onlyAfterDealine {
        require(state == ProjectStatus.Failed, "Project is not failed");

        uint256 totalRefund = 0;
        for(uint i =0; i < donations.length; i++){
               if (donations[i].donor == msg.sender){
                   totalRefund += donations[i].amount;
                   donations[i].amount = 0;
               }
        }

        require(totalRefund > 0, "No funds to refund");

        payable(msg.sender).transfer(totalRefund);

        emit FundsRefunded(msg.sender, totalRefund);
    }

    function updateProjectState() external onlyAfterDealine {
        require(state == ProjectStatus.Ongoing,"Project is already finalized");

        if (currentAmount >= goalAmount){
            state = ProjectStatus.Successful;
        } else {
            state = ProjectStatus.Failed;
        }

        emit ProjectStateChanged(state);
    }
}

