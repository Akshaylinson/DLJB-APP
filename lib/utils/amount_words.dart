class AmountWords {
  static const _ones = ['', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
    'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'];
  static const _tens = ['', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'];

  static String convert(double amount) {
    if (amount == 0) return 'Rupees Zero Only.';
    final rupees = amount.truncate();
    final paise  = ((amount - rupees) * 100).round();
    var result = 'Rupees ${_inWords(rupees)}';
    if (paise > 0) result += 'and $paise Paise ';
    return '${result.trim()} Only.';
  }

  static String _inWords(int n) {
    if (n == 0) return '';
    if (n < 20) return '${_ones[n]} ';
    if (n < 100) return '${_tens[n ~/ 10]} ${_ones[n % 10]} '.replaceAll('  ', ' ');
    if (n < 1000) return '${_ones[n ~/ 100]} Hundred ${_inWords(n % 100)}';
    if (n < 100000) return '${_inWords(n ~/ 1000)}Thousand ${_inWords(n % 1000)}';
    if (n < 10000000) return '${_inWords(n ~/ 100000)}Lakh ${_inWords(n % 100000)}';
    return '${_inWords(n ~/ 10000000)}Crore ${_inWords(n % 10000000)}';
  }
}
