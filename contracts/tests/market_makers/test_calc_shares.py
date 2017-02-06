from ..abstract_test import AbstractTestContract
import math


class TestContract(AbstractTestContract):
    """
    run test with python -m unittest contracts.tests.market_makers.test_calc_shares
    """

    def __init__(self, *args, **kwargs):
        super(TestContract, self).__init__(*args, **kwargs)
        self.deploy_contracts = [self.lmsr_name, self.math_library_name]

    @staticmethod
    def calc_shares(tokens, outcome, share_distribution, b):
        return b * math.log(
            sum([math.exp(share_count / b + tokens / b) for share_count in share_distribution]) -
            sum([math.exp(share_count / b) for index, share_count in enumerate(share_distribution) if index != outcome])
        ) - share_distribution[outcome]

    def test(self):
        # Calculating costs for buying shares and earnings for selling shares
        outcome = 1
        initial_funding = self.MIN_MARKET_BALANCE
        share_distribution = [initial_funding, initial_funding]
        number_of_shares = 5*10**18
        b = initial_funding/float(math.log(len(share_distribution)))
        tokens = self.lmsr.calcCostsBuying(
            "".zfill(64).decode('hex'), initial_funding, share_distribution, outcome, number_of_shares
        )
        approx_number_of_shares = self.calc_shares(tokens, outcome, share_distribution, b)
        self.assertAlmostEqual(number_of_shares/approx_number_of_shares, 1, 3)
