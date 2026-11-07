import pytest
from app.validation.study_metrics import agreement_metrics, sus_score


@pytest.mark.parametrize(("answers", "expected"), [
    ([5, 1] * 5, 100), ([1, 5] * 5, 0), ([3] * 10, 50),
    ([4, 2] * 5, 75),
])
def test_sus_polarity_and_scale(answers, expected):
    assert sus_score(answers) == expected


@pytest.mark.parametrize("answers", [[1] * 9, [0] * 10, [6] * 10, [True] * 10, [3.0] * 10])
def test_sus_invalid_responses_are_not_imputed(answers):
    with pytest.raises(ValueError):
        sus_score(answers)


def test_identical_measurements_have_perfect_agreement():
    result = agreement_metrics([10, 20, 30], [10, 20, 30])
    assert result["icc_a1"] == pytest.approx(1)
    assert result["bias_retest_minus_baseline"] == 0


def test_systematic_shift_reduces_absolute_agreement_despite_perfect_correlation():
    result = agreement_metrics([10, 20, 30], [20, 30, 40])
    assert result["icc_a1"] == pytest.approx(2 / 3)
    assert result["bias_retest_minus_baseline"] == 10
    assert result["agreement_lower"] == 10


@pytest.mark.parametrize(("first", "second"), [([1, 2], [1, 2]), ([1, 2, 3], [1]),
    ([1, 1, 1], [1, 1, 1]), ([1, 2, 3], [1, float('nan'), 3])])
def test_undefined_agreement_is_rejected(first, second):
    with pytest.raises(ValueError):
        agreement_metrics(first, second)
