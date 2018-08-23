
pragma solidity ^0.4.11;

/**
 * Math operations with safety checks
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);

    return a - b;
  }


  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;
  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }
  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }

}

contract Adminable is Ownable{
  address public admin;
  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public{
  }
  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyAdminAndOwner() {
    require((msg.sender == owner) || (msg.sender == admin));
    _;
  }

  function setAdmin(address newAdmin) public onlyOwner {
    require(newAdmin != address(0));
    admin = newAdmin;
  }

}



contract CourseContract is Adminable {
	using SafeMath for uint;

    string public name = "BitWork Course Sale Conrtact";

	FundContract public fundContract;

	uint public ethusd;

	uint public firstCoursePrice = 250;
	uint public secondCoursePrice = 500;
//	uint public maxFirstFundAmount = 10000;


	uint public firstCoursePriceWei;
	uint public secondCoursePriceWei;
//	uint public maxFirstFundAmountWei;

	//we accept payments even if they 10% less then official price
	uint minFirstCoursePriceWei;
	uint minSecondCoursePriceWei;

	//we don't give change back if payment exceeds price less then 10%
	uint maxFirstCoursePriceWei;
	uint maxSecondCoursePriceWei;

	event FirstCourseBought();
	event SecondCourseBought();

	mapping (address => address) public sponsors;

	mapping (address => uint) public pending; //information about payments made until link to the sponsor was set

//	uint payedForCourse;

	uint totalPayedSumWei;

	// we assume that bonuses are equal for both courses
	uint courseLevelOneBonus = 20;
	uint courseLevelTwoBonus = 10;
	uint courseLevelThreeBonus = 10;
	uint courseLevelFourBonus = 5;
	uint courseLevelFiveBonus = 5;

	bool public coursePaymentsAreStopped = false;

	function CourseContract(uint256 _ethusd) public {
		require(_ethusd > 0);
		//require(_ethusd < 50000); //for testing purpuses

		sponsors[owner] = owner; //for any case, not obligated

		fundContract = new FundContract(this);

		ethusd = _ethusd;
//		fundContract.setETHPrice(ethusd);

		pricesRecalculation();
	}

	function setFundContract(address _fundContract) public onlyOwner {
		fundContract = FundContract(_fundContract);
		fundContract.setETHPrice(ethusd);

	}

	function () public payable {
		require(!coursePaymentsAreStopped);

		uint value = msg.value;
		require (value > minFirstCoursePriceWei);

		if (value <= maxFirstCoursePriceWei) {
			courseBought(msg.sender, value);
			emit FirstCourseBought();
			return;
		}
		if (value <= minSecondCoursePriceWei) {
			//выплатить сдачу
			uint cashBack = value.sub(firstCoursePriceWei);
			msg.sender.transfer(cashBack);
			courseBought(msg.sender, firstCoursePriceWei);
			emit FirstCourseBought();
			return;
		}
		if (value <= maxSecondCoursePriceWei) {
			courseBought(msg.sender, value);
			emit SecondCourseBought();
			return;
		}
		if (value > maxSecondCoursePriceWei) {
			//выплатить сдачу
			msg.sender.transfer(value.sub(secondCoursePriceWei));
			courseBought(msg.sender, secondCoursePriceWei);
			emit SecondCourseBought();
			return;
		}

	}
	/* if difference between payment and course price is less then 10% we accept them even if payment is less then course price
	in this cases we also pay bonuses as the whole course price was payed
	the "realPayedPrice" parameter is used to calculate the owners transfer amount
	*/
	function courseBought(address buyer, uint realPayedPrice) internal{
		address sponsor1 = sponsors[buyer];
		uint bonusesPayed = 0;
		uint bonusAmount;

		if (sponsors[buyer] == address(0)) {
			pending[buyer] = pending[buyer].add(realPayedPrice);
			return;
		}
		if (sponsor1 == owner) {
			owner.transfer(realPayedPrice);
			return;
		}
		bonusAmount = firstCoursePriceWei.mul(courseLevelOneBonus).div(100);
		sponsor1.transfer(bonusAmount);
		bonusesPayed = bonusesPayed.add(bonusAmount);

		address sponsor2 = sponsors[sponsor1];
		if (sponsor2 == address(0))
			sponsor2 = owner;
		if (sponsor2 == owner) {
			owner.transfer(realPayedPrice.sub(bonusesPayed));
			return;
		}
		bonusAmount = firstCoursePriceWei.mul(courseLevelTwoBonus).div(100);
		sponsor2.transfer(bonusAmount);
		bonusesPayed = bonusesPayed.add(bonusAmount);

		if (sponsor3 == address(0))
			sponsor3 = owner;
		address sponsor3 = sponsors[sponsor2];
		if (sponsor3 == owner) {
			owner.transfer(realPayedPrice.sub(bonusesPayed));
			return;
		}
		bonusAmount = firstCoursePriceWei.mul(courseLevelThreeBonus).div(100);
		sponsor3.transfer(bonusAmount);
		bonusesPayed = bonusesPayed.add(bonusAmount);

		address sponsor4 = sponsors[sponsor3];
		if (sponsor4 == address(0))
			sponsor4 = owner;
		if (sponsor4 == owner) {
			owner.transfer(realPayedPrice.sub(bonusesPayed));
			return;
		}
		bonusAmount = firstCoursePriceWei.mul(courseLevelFourBonus).div(100);
		sponsor4.transfer(bonusAmount);
		bonusesPayed = bonusesPayed.add(bonusAmount);

		address sponsor5 = sponsors[sponsor4];
		if (sponsor5 == address(0))
			sponsor5 = owner;
		if (sponsor5 == owner) {
			owner.transfer(realPayedPrice.sub(bonusesPayed));
			return;
		}
		bonusAmount = firstCoursePriceWei.mul(courseLevelFiveBonus).div(100);
		sponsor5.transfer(bonusAmount);
		bonusesPayed = bonusesPayed.add(bonusAmount);

		owner.transfer(realPayedPrice.sub(bonusesPayed));
	}

	function setSponsorInfo(address newMember, address sponsor) public onlyAdminAndOwner{

//		require (sponsors[newMember] == address(0)); //this line is hidden becouse Admin can make a mistake

        require (sponsors[sponsor] != address(0)); //Admin should set sponsor info ONLY in right order. It's forbidden, to set as a sponsor person, who haven't sponsor yet
        
		if (sponsor == address(0)) //if there aren't sponsors, all bonuses should get the owner
			sponsor = owner;

		sponsors[newMember] = sponsor;

		uint pendingAmount = pending[newMember];
		if (pendingAmount > 0) {
			courseBought(newMember, pendingAmount);
			pending[newMember] = 0; //не обязательно, ведь sponsors[newMember] уже не ноль и в следующий раз это просто не пройдет require в начале функции
		}

		//pass information to fundContract and check their pending records
		fundContract.newSponsorInfo(newMember);

	}
	
	function testSetSponsorInfo(address newMember, address sponsor) public onlyAdminAndOwner{

		//pass information to fundContract and check their pending records
		fundContract.newSponsorInfo(newMember);

	}
	

	//maybe we don't use such getter because we can assess to sponsors directly
	function getSponsor(address member) public view returns (address){
		return sponsors[member];
	}


	function setETHPrice(uint _price) public onlyOwner{
		require(_price > 0);
		//require(_price < 5000);

		ethusd = _price;
		fundContract.setETHPrice(_price);
		pricesRecalculation();

	}

	function setFirstCoursePrice(uint _newPrice) public onlyOwner {
		require(_newPrice > 0);
		require(_newPrice < 5000);

		firstCoursePrice = _newPrice;
		pricesRecalculation();
	}

	function setSecondCoursePrice(uint _newPrice) public onlyOwner {
		require(_newPrice > 0);
		require(_newPrice < 5000);

		secondCoursePrice = _newPrice;
		pricesRecalculation();
	}

	function pricesRecalculation() internal {
		firstCoursePriceWei = firstCoursePrice.mul(10**18).div(ethusd);
		secondCoursePriceWei = secondCoursePrice.mul(10**18).div(ethusd);

		minFirstCoursePriceWei = firstCoursePriceWei.mul(90).div(100);
		minSecondCoursePriceWei = secondCoursePriceWei.mul(90).div(100);

		maxFirstCoursePriceWei = firstCoursePriceWei.mul(110).div(100);
		maxSecondCoursePriceWei = secondCoursePriceWei.mul(110).div(100);

	}

	function stopCoursePayments() onlyOwner public {
		coursePaymentsAreStopped = true;
	}

	function resumeCoursePayments() onlyOwner public {
		coursePaymentsAreStopped = false;
	}



}



contract FundContract is Adminable{
	using SafeMath for uint;

    string public name = "BitWork Fund Conrtact";

	CourseContract public courseContract;
//    address public courseContract;

	uint public ethusd;

	mapping (address => uint) public pending;

	uint public fundOneInvestorPersent = 50;
	uint fundOneSponsorOnePersent = 4;
	uint fundOneSponsorTwoPersent = 3;
	uint fundOneSponsorThreePersent = 3;
	uint fundOneSponsorFourPersent = 0;

	uint fundTwoInvestorPersent = 100;
	uint fundTwoSponsorOnePersent = 8;
	uint fundTwoSponsorTwoPersent = 6;
	uint fundTwoSponsorThreePersent = 3;
	uint fundTwoSponsorFourPersent = 3;

	uint public totalPaymentsUSD = 0; // the sum of payments have been made for investors and sponsors
	uint totalPaymentsWei = 0;
	uint public totalInvestmentsUSD = 0;
	uint totalInvestmentsWei = 0;

	uint maxFirstFundAmountUSD = 10000;
	uint divisionInaccuracyProtection = 20; //we store deposits and payment sums in USD, but perform transactions in ETH, so in calculations and roundings could be some inaccurancies.

	uint public period = 30 days; //in testing perpuses we can set it to 1 hour for example

	bool public fundPaymentsAreStopped = false;
	
	uint public testTimeShift = 0; //for test perpuses only. It shifts all timestampts "now" on this value

	struct Entry {
		address person;
		uint value; //deposit value in USD
		uint persent; // share of deposit, which person gets at the end of deposit period (withno investor payment end refunding)
		uint fund; // type of fund (1 or 2)
		bool isInvestor; //(is Investor of sponsor)
		uint startTime;
		uint withdrawn; //only in USD!
	}

	Entry[] public deposits;

	function FundContract(address _courseContract) public {
		courseContract = CourseContract(_courseContract);
	}

	function newDeposit(address _person, uint _value, uint _persent, uint _fund, bool _isInvestor, uint _startTime) internal{
		Entry memory newEntry;
		newEntry = Entry({
			person: _person,
			value: _value,
			persent: _persent,
			fund: _fund,
			isInvestor: _isInvestor,
			startTime: _startTime,
			withdrawn: 0
		});
		deposits.push(newEntry);
	}

	function () public payable {
	    require(ethusd > 0); 
	    
		if ((msg.sender == owner) || (msg.sender == admin)) {
		    uint balance = address(this).balance;
			uint usdBalance = toUSD(balance);
			uint howMuchToPay = getAmountToPayNow();
			if (usdBalance >= howMuchToPay + divisionInaccuracyProtection)
				makePayments();
			return;
		}
		require(!fundPaymentsAreStopped); //надо проверить, что выплаты по депозитам можно производить и после завершения приема средств

		uint mv = msg.value;  //for inner checks, why totalInvestmentsUSD dont shows correctly
		owner.transfer(msg.value);
		totalInvestmentsWei = totalInvestmentsWei.add(mv);

		uint usdMsgValue = toUSD(mv);
		totalInvestmentsUSD = totalInvestmentsUSD.add(usdMsgValue);

		address sponsor = courseContract.sponsors(msg.sender);
		if (sponsor == address(0)) {
			uint pended = pending[msg.sender];
			pending[msg.sender] = pended.add(usdMsgValue); //in case investor made few deposits in one day before admin put information about his sponsors
			return;
		}

		createDepositRecords(msg.sender, usdMsgValue);
	}

	function createDepositRecords(address investor, uint paymentUSD) internal {
		address sponsor = courseContract.sponsors(investor);

		if (paymentUSD < maxFirstFundAmountUSD) { //для разных фондов бонусы разные и разная глубина партнерки

			newDeposit(investor, paymentUSD, fundOneInvestorPersent, 1, true, now + testTimeShift);

			if (sponsor == address(0))
				sponsor = owner;
			if (sponsor == owner)
				return;
			newDeposit(sponsor, paymentUSD, fundOneSponsorOnePersent, 1, false, now + testTimeShift);

			address sponsor2 = courseContract.sponsors(sponsor);
			if (sponsor2 == address(0))
				sponsor2 = owner;
			if (sponsor2 == owner)
				return;
			newDeposit(sponsor2, paymentUSD, fundOneSponsorTwoPersent, 1, false, now + testTimeShift);

			if (sponsor3 == address(0))
				sponsor3 = owner;
			address sponsor3 = courseContract.sponsors(sponsor2);
			if (sponsor3 == owner)
				return;
			newDeposit(sponsor3, paymentUSD, fundOneSponsorThreePersent, 1, false, now + testTimeShift);

			//если первоначальные условия менять не будем, то последняя итерация никогда не сработает
			address sponsor4 = courseContract.sponsors(sponsor3);
			if (sponsor4 == address(0))
				sponsor4 = owner;
			if (sponsor4 == owner)
				return;
			newDeposit(sponsor4, paymentUSD, fundOneSponsorFourPersent, 1, false, now + testTimeShift);

		} else {
			newDeposit(investor, paymentUSD, fundTwoInvestorPersent, 2, true, now + testTimeShift);
			if (sponsor == address(0))
				sponsor = owner;
			if (sponsor == owner)
				return;
			newDeposit(sponsor, paymentUSD, fundTwoSponsorOnePersent, 2, false, now + testTimeShift);

			if (sponsor2 == address(0))
				sponsor2 = owner;
			sponsor2 = courseContract.sponsors(sponsor);
			if (sponsor2 == owner)
				return;
			newDeposit(sponsor2, paymentUSD, fundTwoSponsorTwoPersent, 2, false, now + testTimeShift);

			if (sponsor3 == address(0))
				sponsor3 = owner;
			sponsor3 = courseContract.sponsors(sponsor2);
			if (sponsor3 == owner)
				return;
			newDeposit(sponsor3, paymentUSD, fundTwoSponsorThreePersent, 2, false, now + testTimeShift);

			if (sponsor4 == address(0))
				sponsor4 = owner;
			sponsor4 = courseContract.sponsors(sponsor3);
			if (sponsor4 == owner)
				return;
			newDeposit(sponsor4, paymentUSD, fundTwoSponsorFourPersent, 2, false, now + testTimeShift);
		}
	}

	function makePayments() internal {
		uint length = deposits.length;
		for (uint i = 0; i < length; i++) {    //возможно тут надо заменить на length - 1
			Entry memory deposit = deposits[i];
			uint toPay = totalPersonPaymentsShouldBeDoneToTheMoment (i, now + testTimeShift);
			if (toPay > deposit.withdrawn) {
				uint delta = toPay.sub(deposit.withdrawn);
				deposit.person.transfer(toWei(delta));  //
				deposits[i].withdrawn = toPay;
				totalPaymentsUSD = totalPaymentsUSD.add(delta);
				totalPaymentsWei = totalPaymentsWei.add(toWei(delta));
			}
		}
	}

	function getAmountToPayAtTheMoment(uint time) public view onlyAdminAndOwner returns(uint) {
		require (time >= now + testTimeShift);

		uint length = deposits.length;
		uint sum = 0;

		for (uint i = 0; i < length; i++) {  // maybe we should put length
			//Entry memory deposit = deposits[i];
			uint toPay = totalPersonPaymentsShouldBeDoneToTheMoment (i, time);

			sum = sum.add(toPay).sub(deposits[i].withdrawn);
		}
		return sum;
	}


	function totalPersonPaymentsShouldBeDoneToTheMoment (uint i, uint time) public view returns (uint){
		require (time >= now + testTimeShift);

		uint sum = 0;
		uint persent; // how much persents of all monthly payments person should get till @time

		Entry memory deposit = deposits[i];

		if (deposit.fund == 1) {
			uint monthes = (time - deposit.startTime).div(period);
			if (monthes < 2)
				persent = 0;
			else if (monthes > 6)
				persent = 100;
			else
				persent = (monthes - 1) * 20;

			//sum у нас целое, deposit.value целое, поэтому для уменьшения погрешности все div перенес в конец
			//результат получится целым потому что в конце у нас div
			sum = deposit.persent.mul(deposit.value).mul(persent).div(100).div(100);

			if ((deposit.isInvestor == true) && (monthes > 5))
				sum = sum.add(deposit.value);

			return sum;
		}

		if (deposit.fund == 2) {
			monthes = (time - deposit.startTime).div(period);
			if (monthes < 3)
				persent = 0;
			else if (monthes > 12)
				persent = 100;
			else
				persent = (monthes - 2) * 10;

			//sum у нас целое, deposit.value целое, поэтому для уменьшения погрешности все div перенес в конец
			sum = deposit.persent.mul(deposit.value).mul(persent).div(100).div(100);

			if ((deposit.isInvestor == true) && (monthes > 11))
				sum = sum.add(deposit.value);

			return sum;
		}

	}

	function getAmountToPayNow() public view onlyAdminAndOwner returns(uint) {
		return getAmountToPayAtTheMoment(now + testTimeShift);
	}

	function getAmountToPayTommorow() public view onlyAdminAndOwner returns(uint) {
		return getAmountToPayAtTheMoment(now + testTimeShift + 1 days);

	}
	function getAmountToPayNextWeek() public view onlyAdminAndOwner returns(uint) {
		return getAmountToPayAtTheMoment(now + testTimeShift + 7 days);

	}
	function getAmountToPayNextMonth() public view onlyAdminAndOwner returns(uint) {
		return getAmountToPayAtTheMoment(now + testTimeShift + 30 days);

	}

	function getContractBalanceWei() public view returns(uint){
		return address(this).balance;
	}

	function getContractBalanceUSD() public view returns(uint){
		return toUSD(address(this).balance);
	}
	function withdraw() public onlyOwner {
		owner.transfer(address(this).balance);
	}

	function getTotalInvestmentsUSD() public view onlyAdminAndOwner returns(uint){
		return totalInvestmentsUSD;
	}
	function getTotalInvestmentsWei() public view onlyAdminAndOwner returns(uint){
		return totalInvestmentsWei;
	}
	function getTotalPaymentsUSD() public view onlyAdminAndOwner returns(uint){
		return totalPaymentsUSD;
	}
	function getTotalPaymentsWei() public view onlyAdminAndOwner returns(uint){
		return totalPaymentsWei;
	}

	//проверить, что изменения курса корректно доходят
	function setETHPrice(uint _ethusd) public {
		require (msg.sender == address(courseContract));
		ethusd = _ethusd;
	}


	function toWei(uint usdAmount) public view returns(uint){
		return usdAmount.mul(1 ether).div(ethusd);
	}

	function toUSD(uint weiAmount) public view returns(uint){
		return weiAmount.mul(ethusd).div(1 ether);
	}

	function newSponsorInfo(address newMember) public {
		require (msg.sender == address(courseContract));

		uint pended = pending[newMember];
		if (pended > 0) {
			createDepositRecords(newMember, pended);
			pending[newMember] = 0;
		}
	}

	function stopFundPayments() onlyOwner public {
		fundPaymentsAreStopped = true;
	}

	function resumeFundPayments() onlyOwner public {
		fundPaymentsAreStopped = false;
	}

	function setCourseContract (address _courseContract) public onlyOwner {
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
	function setTestTimeShift(uint _value) public onlyOwner {
	       testTimeShift = _value;
	}
/*	
	function setETHPriceFund(uint _ethusd) public onlyAdminAndOwner {
	    ethusd = _ethusd;
	}
*/	

}
