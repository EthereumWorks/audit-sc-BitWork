// EW "Important" count: 15
// EW "Not critical" count: 4
// EW "Note" count: 15


// EW Ok
pragma solidity ^0.4.11;

/**
 * Math operations with safety checks
 */
// EW Ok
library SafeMath {
    // EW Ok
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // EW Ok
        uint256 c = a * b;
        // EW Ok
        assert(a == 0 || c / a == b);
        // EW Ok
        return c;
    }
    // EW Ok
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // EW Ok
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        // EW Ok
        return c;
    }
    // EW Ok
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        // EW Ok
        assert(b <= a);

        // EW Ok
        return a - b;
    }

    // EW Ok
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        // EW Ok
        uint256 c = a + b;
        // EW Ok
        assert(c >= a);
        // EW Ok
        return c;
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
// EW Ok
contract Ownable {
    // EW Ok
    address public owner;
    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    // EW Ok
    constructor() public {
        // EW Ok
        owner = msg.sender;
    }
    /**
     * @dev Throws if called by any account other than the owner.
     */
    // EW Ok
    modifier onlyOwner() {
        // EW Ok
        require(msg.sender == owner);
        // EW Ok
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    // EW Ok
    function transferOwnership(address newOwner) public onlyOwner {
        // EW Ok
        require(newOwner != address(0));
        // EW Ok
        owner = newOwner;
    }

}
// EW Ok
contract Adminable is Ownable{
    // EW Ok
    address public admin;
    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    // EW Ok
    constructor() public{
    }
    /**
     * @dev Throws if called by any account other than the owner.
     */
    // EW Ok
    modifier onlyAdminAndOwner() {
        // EW Ok
        require((msg.sender == owner) || (msg.sender == admin));
        // EW Ok
        _;
    }
    // EW Ok
    function setAdmin(address newAdmin) public onlyOwner {
        // EW Ok
        require(newAdmin != address(0));
        // EW Ok
        admin = newAdmin;
    }

}


// EW Ok
contract CourseContract is Adminable {
    // EW Ok
    using SafeMath for uint;
    // EW Note: possible typo in the word “Contract”
    string public name = "BitWork Course Sale Conrtact";
    // EW Ok
    FundContract public fundContract;
    // EW Note: If the price of ETH (ethusd) is a public variable, you should be prepared for the fact that buyers can send easily calculated 91% of the price.
    uint public ethusd;
    // EW Ok
    uint public firstCoursePrice = 250;
    // EW Ok
    uint public secondCoursePrice = 500;
    //	uint public maxFirstFundAmount = 10000;

    // EW Ok
    uint public firstCoursePriceWei;
    // EW Ok
    uint public secondCoursePriceWei;

    //	uint public maxFirstFundAmountWei;

    //we accept payments even if they 10% less then official price
    // EW Ok
    uint minFirstCoursePriceWei;
    // EW Ok
    uint minSecondCoursePriceWei;


    //we don't give change back if payment exceeds price less then 10%
    // EW Ok
    uint maxFirstCoursePriceWei;
    // EW Ok
    uint maxSecondCoursePriceWei;

    // EW Ok
    event FirstCourseBought();
    // EW Ok
    event SecondCourseBought();

    // EW Ok
    mapping (address => address) public sponsors;

    // EW Ok
    mapping (address => uint) public pending; //information about payments made until link to the sponsor was set


    //	uint payedForCourse;
    // EW Ok
    uint totalPayedSumWei;


    // we assume that bonuses are equal for both courses
    // EW Ok
    uint courseLevelOneBonus = 20;
    // EW Ok
    uint courseLevelTwoBonus = 10;
    // EW Ok
    uint courseLevelThreeBonus = 10;
    // EW Ok
    uint courseLevelFourBonus = 5;
    // EW Ok
    uint courseLevelFiveBonus = 5;

    // EW Ok
    bool public coursePaymentsAreStopped = false;

    // EW Ok
    function CourseContract(uint256 _ethusd) public {
        // EW Ok
        require(_ethusd > 0);
        //require(_ethusd < 50000); //for testing purpuses
        // EW Ok
        sponsors[owner] = owner; //for any case, not obligated
        // EW Note: two functions contradict each other: the creation of instance of the FundContract in the CourseContract constructor and the setFundContract function which integrates the deployed FundContract. If the FundContract will be intregrated through the setFundContract function, the creation of instance in the constructor was unnecessary. It could be removed to save gas.
        fundContract = new FundContract(this);
        // EW Ok
        ethusd = _ethusd;
        //		fundContract.setETHPrice(ethusd);
        // EW Ok
        pricesRecalculation();
    }
    // EW Note: two functions contradict each other: the creation of instance of the FundContract in the CourseContract constructor and the setFundContract function which integrates the deployed FundContract. If the FundContract will be intregrated through the setFundContract function, the creation of instance in the constructor was unnecessary. It could be removed to save gas.
    function setFundContract(address _fundContract) public onlyOwner {
        // EW Ok
        fundContract = FundContract(_fundContract);
        // EW Ok
        fundContract.setETHPrice(ethusd);

    }
    // EW Ok
    function () public payable {
        // EW Ok
        require(!coursePaymentsAreStopped);
        // EW Ok
        uint value = msg.value;
        // EW Ok
        require (value > minFirstCoursePriceWei);
        // EW Ok
        if (value <= maxFirstCoursePriceWei) {
            // EW Ok
            courseBought(msg.sender, value);
            // EW Ok
            emit FirstCourseBought();
            // EW Ok
            return;
        }
        // EW Ok
        if (value <= minSecondCoursePriceWei) {
            //выплатить сдачу
            // EW Ok
            uint cashBack = value.sub(firstCoursePriceWei);
            // EW Ok
            msg.sender.transfer(cashBack);
            // EW Ok
            courseBought(msg.sender, firstCoursePriceWei);
            // EW Ok
            emit FirstCourseBought();
            // EW Ok
            return;
        }
        // EW Ok
        if (value <= maxSecondCoursePriceWei) {
            // EW Ok
            courseBought(msg.sender, value);
            // EW Ok
            emit SecondCourseBought();
            // EW Ok
            return;
        }
        // EW Ok
        if (value > maxSecondCoursePriceWei) {
            //выплатить сдачу
            // EW Ok
            msg.sender.transfer(value.sub(secondCoursePriceWei));
            // EW Ok
            courseBought(msg.sender, secondCoursePriceWei);
            // EW Ok
            emit SecondCourseBought();
            // EW Ok
            return;
        }

    }
    /* if difference between payment and course price is less then 10% we accept them even if payment is less then course price
    in this cases we also pay bonuses as the whole course price was payed
    the "realPayedPrice" parameter is used to calculate the owners transfer amount
    */
    // EW Ok
    function courseBought(address buyer, uint realPayedPrice) internal{
        // EW Ok
        address sponsor1 = sponsors[buyer];
        // EW Ok
        uint bonusesPayed = 0;
        // EW Ok
        uint bonusAmount;
        // EW Note: sponsors[buyer] can be changed to sponsor1. That variable was created for this.
        if (sponsors[buyer] == address(0)) {
            // EW Ok
            pending[buyer] = pending[buyer].add(realPayedPrice);
            // EW Ok
            return;
        }
        // EW Ok
        if (sponsor1 == owner) {
            // EW Ok
            owner.transfer(realPayedPrice);
            // EW Ok
            return;
        }
        // EW Ok
        bonusAmount = firstCoursePriceWei.mul(courseLevelOneBonus).div(100);
        // EW Ok
        sponsor1.transfer(bonusAmount);
        // EW Ok
        bonusesPayed = bonusesPayed.add(bonusAmount);

        // EW Ok
        address sponsor2 = sponsors[sponsor1];
        // EW Ok
        if (sponsor2 == address(0))
        // EW Ok
            sponsor2 = owner;
        // EW Ok
        if (sponsor2 == owner) {
            // EW Ok
            owner.transfer(realPayedPrice.sub(bonusesPayed));
            // EW Ok
            return;
        }
        bonusAmount = firstCoursePriceWei.mul(courseLevelTwoBonus).div(100);
        // EW Ok
        sponsor2.transfer(bonusAmount);
        // EW Ok
        bonusesPayed = bonusesPayed.add(bonusAmount);
        // EW Ok

        if (sponsor3 == address(0))
        // EW Ok
            sponsor3 = owner;
        // EW Ok
        address sponsor3 = sponsors[sponsor2];
        // EW Ok
        if (sponsor3 == owner) {
            // EW Ok
            owner.transfer(realPayedPrice.sub(bonusesPayed));
            // EW Ok
            return;
        }
        // EW Ok
        bonusAmount = firstCoursePriceWei.mul(courseLevelThreeBonus).div(100);
        // EW Ok
        sponsor3.transfer(bonusAmount);
        // EW Ok
        bonusesPayed = bonusesPayed.add(bonusAmount);

        // EW Ok
        address sponsor4 = sponsors[sponsor3];
        // EW Ok
        if (sponsor4 == address(0))
        // EW Ok
            sponsor4 = owner;
        // EW Ok
        if (sponsor4 == owner) {
            // EW Ok
            owner.transfer(realPayedPrice.sub(bonusesPayed));
            // EW Ok
            return;
        }
        // EW Ok
        bonusAmount = firstCoursePriceWei.mul(courseLevelFourBonus).div(100);
        // EW Ok
        sponsor4.transfer(bonusAmount);
        // EW Ok
        bonusesPayed = bonusesPayed.add(bonusAmount);

        // EW Ok
        address sponsor5 = sponsors[sponsor4];
        // EW Ok
        if (sponsor5 == address(0))
        // EW Ok
            sponsor5 = owner;
        // EW Ok
        if (sponsor5 == owner) {
            // EW Ok
            owner.transfer(realPayedPrice.sub(bonusesPayed));
            // EW Ok
            return;
        }
        // EW Ok
        bonusAmount = firstCoursePriceWei.mul(courseLevelFiveBonus).div(100);
        // EW Ok
        sponsor5.transfer(bonusAmount);
        // EW Ok
        bonusesPayed = bonusesPayed.add(bonusAmount);

        // EW Important: if the sponsor of any level was be the owner of the contract, the function will try to transfer him the full amount of payment twice: in the performance of the conditional statement and at the next line.
        owner.transfer(realPayedPrice.sub(bonusesPayed));
    }
    // EW Ok
    function setSponsorInfo(address newMember, address sponsor) public onlyAdminAndOwner{

        //		require (sponsors[newMember] == address(0)); //this line is hidden becouse Admin can make a mistake
        // EW Ok
        require (sponsors[sponsor] != address(0)); //Admin should set sponsor info ONLY in right order. It's forbidden, to set as a sponsor person, who haven't sponsor yet
        // EW Ok
        if (sponsor == address(0)) //if there aren't sponsors, all bonuses should get the owner
        // EW Ok
            sponsor = owner;
        // EW Ok
        sponsors[newMember] = sponsor;
        // EW Ok
        uint pendingAmount = pending[newMember];
        // EW Ok
        if (pendingAmount > 0) {
            // EW Ok
            courseBought(newMember, pendingAmount);
            // EW Ok
            pending[newMember] = 0; //не обязательно, ведь sponsors[newMember] уже не ноль и в следующий раз это просто не пройдет require в начале функции
        }

        //pass information to fundContract and check their pending records
        // EW Ok
        fundContract.newSponsorInfo(newMember);

    }
    // EW Ok
    function testSetSponsorInfo(address newMember, address sponsor) public onlyAdminAndOwner{

        //pass information to fundContract and check their pending records
        // EW Ok
        fundContract.newSponsorInfo(newMember);

    }


    //maybe we don't use such getter because we can assess to sponsors directly
    // EW Ok
    function getSponsor(address member) public view returns (address){
        // EW Ok
        return sponsors[member];
    }

    // EW Ok
    function setETHPrice(uint _price) public onlyOwner{
        // EW Ok
        require(_price > 0);
        //require(_price < 5000);
        // EW Ok
        ethusd = _price;
        // EW Ok
        fundContract.setETHPrice(_price);
        // EW Ok
        pricesRecalculation();

    }
    // EW Ok
    function setFirstCoursePrice(uint _newPrice) public onlyOwner {
        // EW Ok
        require(_newPrice > 0);
        // EW Ok
        require(_newPrice < 5000);
        // EW Ok
        firstCoursePrice = _newPrice;
        // EW Ok
        pricesRecalculation();
    }
    // EW Ok
    function setSecondCoursePrice(uint _newPrice) public onlyOwner {
        // EW Ok
        require(_newPrice > 0);
        // EW Ok
        require(_newPrice < 5000);

        // EW Ok
        secondCoursePrice = _newPrice;
        // EW Ok
        pricesRecalculation();
    }
    // EW Ok
    function pricesRecalculation() internal {
        // EW Ok
        firstCoursePriceWei = firstCoursePrice.mul(10**18).div(ethusd);
        // EW Ok
        secondCoursePriceWei = secondCoursePrice.mul(10**18).div(ethusd);
        // EW Ok
        minFirstCoursePriceWei = firstCoursePriceWei.mul(90).div(100);
        // EW Ok
        minSecondCoursePriceWei = secondCoursePriceWei.mul(90).div(100);
        // EW Ok
        maxFirstCoursePriceWei = firstCoursePriceWei.mul(110).div(100);
        // EW Ok
        maxSecondCoursePriceWei = secondCoursePriceWei.mul(110).div(100);

    }
    // EW Ok
    function stopCoursePayments() onlyOwner public {
        // EW Ok
        coursePaymentsAreStopped = true;
    }
    // EW Ok
    function resumeCoursePayments() onlyOwner public {
        // EW Ok
        coursePaymentsAreStopped = false;
    }



}


// EW Ok
contract FundContract is Adminable{
    // EW Ok
    using SafeMath for uint;
    // EW Note: possible typo in the word “Contract”;
    string public name = "BitWork Fund Conrtact";
    // EW Ok
    CourseContract public courseContract;
    //    address public courseContract;
    // EW Ok
    uint public ethusd;
    // EW Ok
    mapping (address => uint) public pending;
    // EW Ok
    uint public fundOneInvestorPersent = 50;
    // EW Ok
    uint fundOneSponsorOnePersent = 4;
    // EW Note: if the variables have the same value it is possible to join them, since there is no function to change them.
    uint fundOneSponsorTwoPersent = 3;
    // EW Note: if the variables have the same value it is possible to join them, since there is no function to change them.
    uint fundOneSponsorThreePersent = 3;
    // EW Ok
    uint fundOneSponsorFourPersent = 0;

    // EW Note: Possible redundancy of functionality: the second tariff is economically less profitable, because it is possible to invest twice in a row for 6 months each time for profit to be 125%. Users will not apply to the second type deposit.
    uint fundTwoInvestorPersent = 100;
    // EW Ok
    uint fundTwoSponsorOnePersent = 8;
    // EW Ok
    uint fundTwoSponsorTwoPersent = 6;
    // EW Note: if the variables have the same value it is possible to join them, since there is no function to change them.
    uint fundTwoSponsorThreePersent = 3;
    // EW Note: if the variables have the same value it is possible to join them, since there is no function to change them.
    uint fundTwoSponsorFourPersent = 3;
    // EW Ok
    uint public totalPaymentsUSD = 0; // the sum of payments have been made for investors and sponsors
    // EW Ok
    uint totalPaymentsWei = 0;
    // EW Ok
    uint public totalInvestmentsUSD = 0;
    // EW Ok
    uint totalInvestmentsWei = 0;
    // EW Note: users can can easily get around limit of the first type deposits by splitting a large amount into smaller amounts and making deposits from different Ethereum anonymous addresses.
    uint maxFirstFundAmountUSD = 10000;
    // EW Ok
    uint divisionInaccuracyProtection = 20; //we store deposits and payment sums in USD, but perform transactions in ETH, so in calculations and roundings could be some inaccurancies.
    // EW Ok
    uint public period = 30 days; //in testing perpuses we can set it to 1 hour for example
    // EW Ok
    bool public fundPaymentsAreStopped = false;
    // EW Important: since the contract has a function setTestTimeShift, timeshift is recommended to be removed to eliminate the possibility of interference to the system.
    uint public testTimeShift = 0; //for test perpuses only. It shifts all timestampts "now" on this value
    // EW Ok
    struct Entry {
        // EW Ok
        address person;
        // EW Ok
        uint value; //deposit value in USD
        // EW Note: parameter has a grammatical error (persent): correctly – percent.
        uint persent; // share of deposit, which person gets at the end of deposit period (withno investor payment end refunding)
        // EW Ok
        uint fund; // type of fund (1 or 2)
        // EW Ok
        bool isInvestor; //(is Investor of sponsor)
        // EW Ok
        uint startTime;
        // EW Ok
        uint withdrawn; //only in USD!
    }
    // EW Ok
    Entry[] public deposits;
    // EW Ok
    function FundContract(address _courseContract) public {
        // EW Ok
        courseContract = CourseContract(_courseContract);
    }
    // EW Ok
    function newDeposit(address _person, uint _value, uint _persent, uint _fund, bool _isInvestor, uint _startTime) internal{
        // EW Ok
        Entry memory newEntry;
        // EW Ok
        newEntry = Entry({
            // EW Ok
            person: _person,
            // EW Ok
            value: _value,
            // EW Ok
            persent: _persent,
            // EW Ok
            fund: _fund,
            // EW Ok
            isInvestor: _isInvestor,
            // EW Ok
            startTime: _startTime,
            // EW Ok
            withdrawn: 0
            });
        // EW Ok
        deposits.push(newEntry);
    }

    // EW Ok
    function () public payable {
        // EW Ok
        require(ethusd > 0);

        // EW Ok
        if ((msg.sender == owner) || (msg.sender == admin)) {
            // EW Ok
            uint balance = address(this).balance;
            // EW Ok
            uint usdBalance = toUSD(balance);
            // EW Ok
            uint howMuchToPay = getAmountToPayNow();
            // EW Ok
            if (usdBalance >= howMuchToPay + divisionInaccuracyProtection)
            // EW Ok
                makePayments();
            // EW Ok
            return;
        }
        // EW Ok
        require(!fundPaymentsAreStopped); //надо проверить, что выплаты по депозитам можно производить и после завершения приема средств
        // EW Ok
        uint mv = msg.value;  //for inner checks, why totalInvestmentsUSD dont shows correctly
        // EW Ok
        owner.transfer(msg.value);
        // EW Ok
        totalInvestmentsWei = totalInvestmentsWei.add(mv);

        // EW Ok
        uint usdMsgValue = toUSD(mv);
        // EW Ok
        totalInvestmentsUSD = totalInvestmentsUSD.add(usdMsgValue);

        // EW Not critical: the excessive functionality: createDepositRecords() (paragraph 6) will do the same operation
        address sponsor = courseContract.sponsors(msg.sender);
        // EW Ok
        if (sponsor == address(0)) {
            // EW Ok
            uint pended = pending[msg.sender];
            // EW Ok
            pending[msg.sender] = pended.add(usdMsgValue); //in case investor made few deposits in one day before admin put information about his sponsors
            // EW Ok
            return;
        }
        // EW Ok
        createDepositRecords(msg.sender, usdMsgValue);
    }
    // EW Note: title of the function as “createDepositRecord” is more appropriate by its meaning.
    function createDepositRecords(address investor, uint paymentUSD) internal {
        // EW Ok
        address sponsor = courseContract.sponsors(investor);

        // EW Important: function divides tariff payments accordingly to the amount of money, not to the customer's preference, which makes it impossible to call this function correctly if the customer wants to invest more than the maximum of the first tariff for a period of 6 months, and Vice versa, if the customer wants to invest a small amount for 12 months.
        if (paymentUSD < maxFirstFundAmountUSD) { //для разных фондов бонусы разные и разная глубина партнерки

            // EW Ok
            newDeposit(investor, paymentUSD, fundOneInvestorPersent, 1, true, now + testTimeShift);

            // EW Ok
            if (sponsor == address(0))
            // EW Ok
                sponsor = owner;
            // EW Ok
            if (sponsor == owner)
            // EW Ok
                return;
            // EW Ok
            newDeposit(sponsor, paymentUSD, fundOneSponsorOnePersent, 1, false, now + testTimeShift);

            // EW Ok
            address sponsor2 = courseContract.sponsors(sponsor);
            // EW Ok
            if (sponsor2 == address(0))
            // EW Ok
                sponsor2 = owner;
            // EW Ok
            if (sponsor2 == owner)
            // EW Ok
                return;
            // EW Ok
            newDeposit(sponsor2, paymentUSD, fundOneSponsorTwoPersent, 1, false, now + testTimeShift);

            if (sponsor3 == address(0))
            // EW Ok
                sponsor3 = owner;
            // EW Important: next line should be set before a conditional statement
            address sponsor3 = courseContract.sponsors(sponsor2);
            // EW Ok
            if (sponsor3 == owner)
            // EW Ok
                return;
            // EW Ok
            newDeposit(sponsor3, paymentUSD, fundOneSponsorThreePersent, 1, false, now + testTimeShift);

            //если первоначальные условия менять не будем, то последняя итерация никогда не сработает
            // EW Ok
            address sponsor4 = courseContract.sponsors(sponsor3);
            // EW Ok
            if (sponsor4 == address(0))
            // EW Ok
                sponsor4 = owner;
            // EW Ok
            if (sponsor4 == owner)
            // EW Ok
                return;
            // EW Ok
            newDeposit(sponsor4, paymentUSD, fundOneSponsorFourPersent, 1, false, now + testTimeShift);
        // EW Important: function divides tariff payments accordingly to the amount of money, not to the customer's preference, which makes it impossible to call this function correctly if the customer wants to invest more than the maximum of the first tariff for a period of 6 months, and Vice versa, if the customer wants to invest a small amount for 12 months.
        } else {
            // EW Ok
            newDeposit(investor, paymentUSD, fundTwoInvestorPersent, 2, true, now + testTimeShift);
            // EW Ok
            if (sponsor == address(0))
            // EW Ok
                sponsor = owner;
            // EW Ok
            if (sponsor == owner)
            // EW Ok
                return;
            // EW Ok
            newDeposit(sponsor, paymentUSD, fundTwoSponsorOnePersent, 2, false, now + testTimeShift);
            // EW Ok
            if (sponsor2 == address(0))
            // EW Ok
                sponsor2 = owner;
            // EW Important: next line should be set before a conditional statement
            sponsor2 = courseContract.sponsors(sponsor);
            // EW Ok
            if (sponsor2 == owner)
            // EW Ok
                return;
            // EW Ok
            newDeposit(sponsor2, paymentUSD, fundTwoSponsorTwoPersent, 2, false, now + testTimeShift);

            // EW Ok
            if (sponsor3 == address(0))
            // EW Ok
                sponsor3 = owner;
            // EW Important: next line should be set before a conditional statement
            sponsor3 = courseContract.sponsors(sponsor2);
            // EW Ok
            if (sponsor3 == owner)
            // EW Ok
                return;
            // EW Ok
            newDeposit(sponsor3, paymentUSD, fundTwoSponsorThreePersent, 2, false, now + testTimeShift);

            // EW Not critical: function checks the presence of the fourth-level sponsor which according the rules will receive nothing.
            if (sponsor4 == address(0))
            // EW Ok
                sponsor4 = owner;
            // EW Important: next line should be set before a conditional statement
            sponsor4 = courseContract.sponsors(sponsor3);
            // EW Ok
            if (sponsor4 == owner)
            // EW Ok
                return;
            // EW Ok
            newDeposit(sponsor4, paymentUSD, fundTwoSponsorFourPersent, 2, false, now + testTimeShift);
        }
    }

    // EW Ok
    function makePayments() internal {
        // EW Ok
        uint length = deposits.length;
        // EW Ok
        for (uint i = 0; i < length; i++) {    //возможно тут надо заменить на length - 1
            // EW Ok
            Entry memory deposit = deposits[i];
            // EW Important: function is called with a space between the function name and parentheses with parameters.
            uint toPay = totalPersonPaymentsShouldBeDoneToTheMoment (i, now + testTimeShift);
            // EW Ok
            if (toPay > deposit.withdrawn) {
                // EW Ok
                uint delta = toPay.sub(deposit.withdrawn);
                // EW Ok
                deposit.person.transfer(toWei(delta));  //
                // EW Ok
                deposits[i].withdrawn = toPay;
                // EW Ok
                totalPaymentsUSD = totalPaymentsUSD.add(delta);
                // EW Ok
                totalPaymentsWei = totalPaymentsWei.add(toWei(delta));

            }
        }
    }

    // EW Ok
    function getAmountToPayAtTheMoment(uint time) public view onlyAdminAndOwner returns(uint) {
        // EW Ok
        require (time >= now + testTimeShift);

        // EW Ok
        uint length = deposits.length;
        // EW Ok
        uint sum = 0;

        // EW Ok
        for (uint i = 0; i < length; i++) {  // maybe we should put length

            //Entry memory deposit = deposits[i];

            // EW Important: function is called with a space between the function name and parentheses with parameters.
            uint toPay = totalPersonPaymentsShouldBeDoneToTheMoment (i, time);

            // EW Ok
            sum = sum.add(toPay).sub(deposits[i].withdrawn);
        }
        // EW Ok
        return sum;
    }


    // EW Ok
    function totalPersonPaymentsShouldBeDoneToTheMoment (uint i, uint time) public view returns (uint){
        // EW Ok
        require (time >= now + testTimeShift);

        // EW Ok
        uint sum = 0;
        // EW Ok
        uint persent; // how much persents of all monthly payments person should get till @time

        // EW Ok
        Entry memory deposit = deposits[i];

        // EW Ok
        if (deposit.fund == 1) {
            // EW Note: grammatical error, must be months.
            uint monthes = (time - deposit.startTime).div(period);
            // EW Ok
            if (monthes < 2)
            // EW Ok
                persent = 0;
            // EW Ok
            else if (monthes > 6)
            // EW Important: Total Interest of the first type deposit is equal to 100% (should be 50).
                persent = 100;
            // EW Ok
            else
            // EW Important: Month Interest of the first type deposit is equal to 20% (should be 10).
                persent = (monthes - 1) * 20;

            //sum у нас целое, deposit.value целое, поэтому для уменьшения погрешности все div перенес в конец
            //результат получится целым потому что в конце у нас div
            // EW Important: Formula of the total amount to be paid contains interest twice in a row.
            sum = deposit.persent.mul(deposit.value).mul(persent).div(100).div(100);

            // EW Ok
            if ((deposit.isInvestor == true) && (monthes > 5))
            // EW Ok
                sum = sum.add(deposit.value);

            // EW Ok
            return sum;
        }

        // EW Ok
        if (deposit.fund == 2) {
            // EW Ok
            monthes = (time - deposit.startTime).div(period);
            // EW Ok
            if (monthes < 3)
            // EW Ok
                persent = 0;
            // EW Ok
            else if (monthes > 12)
            // EW Ok
                persent = 100;
            // EW Ok
            else
            // EW Ok
                persent = (monthes - 2) * 10;

            //sum у нас целое, deposit.value целое, поэтому для уменьшения погрешности все div перенес в конец
            // EW Ok
            sum = deposit.persent.mul(deposit.value).mul(persent).div(100).div(100);

            // EW Ok
            if ((deposit.isInvestor == true) && (monthes > 11))
            // EW Ok
                sum = sum.add(deposit.value);

            // EW Ok
            return sum;
        }

    }
    // EW Ok
    function getAmountToPayNow() public view onlyAdminAndOwner returns(uint) {
        // EW Ok
        return getAmountToPayAtTheMoment(now + testTimeShift);
    }

    // EW Ok
    function getAmountToPayTommorow() public view onlyAdminAndOwner returns(uint) {
        // EW Ok
        return getAmountToPayAtTheMoment(now + testTimeShift + 1 days);

    }
    // EW Ok
    function getAmountToPayNextWeek() public view onlyAdminAndOwner returns(uint) {
        // EW Ok
        return getAmountToPayAtTheMoment(now + testTimeShift + 7 days);

    }
    // EW Ok
    function getAmountToPayNextMonth() public view onlyAdminAndOwner returns(uint) {
        // EW Ok
        return getAmountToPayAtTheMoment(now + testTimeShift + 30 days);

    }

    // EW Ok
    function getContractBalanceWei() public view returns(uint){
        // EW Ok
        return address(this).balance;
    }

    // EW Ok
    function getContractBalanceUSD() public view returns(uint){
        // EW Ok
        return toUSD(address(this).balance);
    }
    // EW Ok
    function withdraw() public onlyOwner {
        // EW Ok
        owner.transfer(address(this).balance);
    }

    // EW Ok
    function getTotalInvestmentsUSD() public view onlyAdminAndOwner returns(uint){
        // EW Ok
        return totalInvestmentsUSD;
    }
    // EW Ok
    function getTotalInvestmentsWei() public view onlyAdminAndOwner returns(uint){
        // EW Ok
        return totalInvestmentsWei;
    }
    // EW Ok
    function getTotalPaymentsUSD() public view onlyAdminAndOwner returns(uint){
        // EW Ok
        return totalPaymentsUSD;
    }
    // EW Ok
    function getTotalPaymentsWei() public view onlyAdminAndOwner returns(uint){
        // EW Ok
        return totalPaymentsWei;
    }

    //проверить, что изменения курса корректно доходят
    // EW Not critical: function should be internal
    function setETHPrice(uint _ethusd) public {
        // EW Ok
        require (msg.sender == address(courseContract));
        // EW Ok
        ethusd = _ethusd;
        // EW Important: function does not trigger any recalculations, thus all USD values saved in the contract are outdated after the price updating.
    }


    // EW Ok
    function toWei(uint usdAmount) public view returns(uint){
        // EW Ok
        return usdAmount.mul(1 ether).div(ethusd);
    }

    // EW Ok
    function toUSD(uint weiAmount) public view returns(uint){
        // EW Ok
        return weiAmount.mul(ethusd).div(1 ether);
    }

    // EW Not critical: function should be internal
    function newSponsorInfo(address newMember) public {
        // EW Ok
        require (msg.sender == address(courseContract));

        // EW Ok
        uint pended = pending[newMember];
        // EW Ok
        if (pended > 0) {
            // EW Ok
            createDepositRecords(newMember, pended);
            // EW Ok
            pending[newMember] = 0;
        }
    }

    // EW Ok
    function stopFundPayments() onlyOwner public {
        // EW Ok
        fundPaymentsAreStopped = true;
    }

    // EW Ok
    function resumeFundPayments() onlyOwner public {
        // EW Ok
        fundPaymentsAreStopped = false;
    }

    // EW Ok
    function setCourseContract (address _courseContract) public onlyOwner {
        // EW Ok
        courseContract = CourseContract(_courseContract);
    }
    /*
        function clearDeposits() public onlyOwner{
            uint length = deposits.length;

            for (uint i = 0; i < length; i++) {

                Entry memory newEntry;
                newEntry = Entry({
                person: address(0),
                value: 0,
                persent: 0,
                fund: 0,
                isInvestor: false,
                startTime: 0,
                withdrawn: 0
            });
            deposits[i] = newEntry;
            }
        }
    */
    // EW Important: this function is recommended to be removed to eliminate the possibility of interference to the system.
    function setTestTimeShift(uint _value) public onlyOwner {
        // EW Ok
        testTimeShift = _value;
    }
    /*
        function setETHPriceFund(uint _ethusd) public onlyAdminAndOwner {
            ethusd = _ethusd;
        }
    */

}
