/*

	FlightDelay with Oraclized Underwriting and Payout
	All times are UTC.
	Copyright (C) Christoph Mussenbrock, Stephan Karpischek

	
    Contract Interfaces
	
*/

@@include('./templatewarning.txt')

pragma solidity @@include('./solidity_version_string.txt');

contract FlightDelayDatabaseModel {


	// Ledger accounts.

	enum Acc {

		Premium,
		RiskFund,
		Payout,
		Balance,
		Reward,
		OraclizeCosts

	}

	// policy Status Codes and meaning:
	//
	// 00 = Applied:	the customer has payed a premium, but the oracle has
	//					not yet checked and confirmed.
	//					The customer can still revoke the policy.
	// 01 = Accepted:	the oracle has checked and confirmed.
	//					The customer can still revoke the policy.
	// 02 = Revoked:	The customer has revoked the policy.
	//					The premium minus cancellation fee is payed back to the
	//					customer by the oracle.
	// 03 = PaidOut:	The flight has ended with delay.
	//					The oracle has checked and payed out.
	// 04 = Expired:	The flight has endet with <15min. delay.
	//					No payout.
	// 05 = Declined:	The application was invalid.
	//					The premium minus cancellation fee is payed back to the
	//					customer by the oracle.
	// 06 = SendFailed:	During Revoke, Decline or Payout, sending ether failed
	//					for unknown reasons.
	//					The funds remain in the contracts RiskFund.


	//                  00       01        02       03
	enum policyState {Applied, Accepted, Revoked, PaidOut,
	//					04      05           06
					  Expired, Declined, SendFailed}

	// oraclize callback types:
	enum oraclizeState { ForUnderwriting, ForPayout }

	// the policy structure: this structure keeps track of the individual parameters of a policy.
	// typically customer address, premium and some status information.

	struct policy {

		// 0 - the customer
		address customer;
		// 1 - premium
		uint premium;

		// risk specific parameters:
		// 2 - pointer to the risk in the risks mapping
		bytes32 riskId;
		// custom payout pattern
		// in future versions, customer will be able to tamper with this array.
		// to keep things simple, we have decided to hard-code the array for all policies.
		// uint8[5] pattern;
		// 3 - probability weight. this is the central parameter
		uint weight;
		// 4 - calculated Payout
		uint calculatedPayout;
		// 5 - actual Payout
		uint actualPayout;

		// status fields:
		// 6 - the state of the policy
		policyState state;
		// 7 - time of last state change
		uint stateTime;
		// 8 - state change message/reason
		bytes32 stateMessage;
		// 9 - TLSNotary Proof
		bytes proof;
	}

	// the risk structure; this structure keeps track of the risk-
	// specific parameters.
	// several policies can share the same risk structure (typically 
	// some people flying with the same plane)

	struct risk {

		// 0 - Airline Code + FlightNumber
		bytes32 carrierFlightNumber;
		// 1 - scheduled departure and arrival time in the format /dep/YYYY/MM/DD
		bytes32 departureYearMonthDay;
		// 2 - the inital arrival time
		uint arrivalTime;
		// 3 - the final delay in minutes
		uint delayInMinutes;
		// 4 - the determined delay category (0-5)
		uint8 delay;
		// 5 - we limit the cumulated weighted premium to avoid cluster risks
		uint cumulatedWeightedPremium;
		// 6 - max cumulated Payout for this risk
		uint premiumMultiplier;
	}

	// the oraclize callback structure: we use several oraclize calls.
	// all oraclize calls will result in a common callback to __callback(...).
	// to keep track of the different querys we have to introduce this struct.
	struct oraclizeCallback {

		// for which policy have we called?
		uint policyId;
		// for which purpose did we call? {ForUnderwrite | ForPayout}
		oraclizeState oState;
		// time 
		uint oraclizeTime;

	}

}
