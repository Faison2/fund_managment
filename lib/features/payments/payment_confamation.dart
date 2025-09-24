import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PaymentConfirmationPage extends StatefulWidget {
  final Map<String, dynamic> transactionData;

  const PaymentConfirmationPage({
    Key? key,
    required this.transactionData,
  }) : super(key: key);

  @override
  State<PaymentConfirmationPage> createState() => _PaymentConfirmationPageState();
}

class _PaymentConfirmationPageState extends State<PaymentConfirmationPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFB8E6D3),
              Color(0xFF98D8C8),
              Color(0xFFF7DC6F),
              Color(0xFFFFE5B4),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.black87,
                          size: 20,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Transaction Receipt',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            const SizedBox(height: 30),

                            // Success Icon
                            ScaleTransition(
                              scale: _scaleAnimation,
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: _getStatusColor(),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _getStatusIcon(),
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Status Title
                            Text(
                              _getStatusTitle(),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Status Subtitle
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40),
                              child: Text(
                                _getStatusSubtitle(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),

                            const SizedBox(height: 30),

                            // Transaction Details Card
                            Expanded(
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 20),
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Transaction Details',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 20),

                                      // Transaction ID
                                      _buildDetailRow(
                                        'Transaction ID',
                                        widget.transactionData['transactionId'] ?? 'TXN${DateTime.now().millisecondsSinceEpoch}',
                                        isCopyable: true,
                                      ),

                                      // Type
                                      _buildDetailRow(
                                        'Type',
                                        widget.transactionData['type'] ?? 'Transaction',
                                      ),

                                      // Amount
                                      _buildDetailRow(
                                        'Amount',
                                        '${widget.transactionData['currency'] ?? 'TSZ'} ${_formatAmount(widget.transactionData['amount']?.toString() ?? '0')}',
                                        isAmount: true,
                                      ),

                                      // Fee (if applicable)
                                      if (widget.transactionData['fee'] != null && widget.transactionData['fee'] > 0)
                                        _buildDetailRow(
                                          'Processing Fee',
                                          '${widget.transactionData['currency'] ?? 'TSZ'} ${_formatAmount(widget.transactionData['fee']?.toString() ?? '0')}',
                                        ),

                                      // Net Amount (for withdrawals)
                                      if (widget.transactionData['netAmount'] != null)
                                        _buildDetailRow(
                                          'Net Amount',
                                          '${widget.transactionData['currency'] ?? 'TSZ'} ${_formatAmount(widget.transactionData['netAmount']?.toString() ?? '0')}',
                                          isAmount: true,
                                        ),

                                      // Payment Method
                                      _buildDetailRow(
                                        widget.transactionData['type'] == 'Deposit' ? 'From' : 'To',
                                        widget.transactionData['paymentMethod'] ?? 'N/A',
                                      ),

                                      // Status
                                      _buildDetailRow(
                                        'Status',
                                        widget.transactionData['status'] ?? 'Processing',
                                        isStatus: true,
                                      ),

                                      // Date & Time
                                      _buildDetailRow(
                                        'Date & Time',
                                        _formatDateTime(DateTime.now()),
                                      ),

                                      // Reference Number (for some transaction types)
                                      if (widget.transactionData['reference'] != null)
                                        _buildDetailRow(
                                          'Reference',
                                          widget.transactionData['reference'],
                                          isCopyable: true,
                                        ),

                                      const SizedBox(height: 20),

                                      // Additional Info based on transaction type
                                      if (widget.transactionData['type'] == 'Withdrawal' ||
                                          widget.transactionData['type'] == 'Dividend Payout')
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: Colors.orange.withOpacity(0.3),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.info_outline,
                                                color: Colors.orange[700],
                                                size: 20,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  'Funds will be transferred to your selected account within 1-3 business days.',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.orange[800],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Action Buttons
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                children: [
                                  // Share Receipt Button
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: _shareReceipt,
                                      icon: const Icon(Icons.share_outlined),
                                      label: const Text('Share Receipt'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                        elevation: 0,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // Download Receipt Button
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: _downloadReceipt,
                                      icon: const Icon(Icons.download_outlined),
                                      label: const Text('Download PDF'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.green,
                                        side: const BorderSide(color: Colors.green),
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // Back to Home Button
                                  SizedBox(
                                    width: double.infinity,
                                    child: TextButton(
                                      onPressed: () {
                                        Navigator.of(context).popUntil((route) => route.isFirst);
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.grey[600],
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                      ),
                                      child: const Text(
                                        'Back to Home',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isCopyable = false, bool isAmount = false, bool isStatus = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isAmount
                          ? Colors.green
                          : isStatus
                          ? _getStatusColor()
                          : Colors.black87,
                    ),
                  ),
                ),
                if (isCopyable) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _copyToClipboard(value),
                    child: Icon(
                      Icons.copy_outlined,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    final status = widget.transactionData['status']?.toString().toLowerCase() ?? 'processing';
    switch (status) {
      case 'success':
      case 'completed':
      case 'successful':
        return Colors.green;
      case 'pending':
      case 'processing':
        return Colors.orange;
      case 'failed':
      case 'error':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon() {
    final status = widget.transactionData['status']?.toString().toLowerCase() ?? 'processing';
    switch (status) {
      case 'success':
      case 'completed':
      case 'successful':
        return Icons.check_circle_outline;
      case 'pending':
      case 'processing':
        return Icons.schedule_outlined;
      case 'failed':
      case 'error':
        return Icons.error_outline;
      default:
        return Icons.schedule_outlined;
    }
  }

  String _getStatusTitle() {
    final status = widget.transactionData['status']?.toString().toLowerCase() ?? 'processing';
    final type = widget.transactionData['type'] ?? 'Transaction';

    switch (status) {
      case 'success':
      case 'completed':
      case 'successful':
        return '$type Successful!';
      case 'pending':
      case 'processing':
        return '$type Processing';
      case 'failed':
      case 'error':
        return '$type Failed';
      default:
        return '$type Initiated';
    }
  }

  String _getStatusSubtitle() {
    final status = widget.transactionData['status']?.toString().toLowerCase() ?? 'processing';
    final type = widget.transactionData['type']?.toString().toLowerCase() ?? 'transaction';

    switch (status) {
      case 'success':
      case 'completed':
      case 'successful':
        return 'Your $type has been completed successfully.';
      case 'pending':
      case 'processing':
        return 'Your $type is being processed. You will be notified once completed.';
      case 'failed':
      case 'error':
        return 'Your $type could not be processed. Please try again or contact support.';
      default:
        return 'Your $type has been initiated and is being processed.';
    }
  }

  String _formatAmount(String amount) {
    if (amount.isEmpty) return '0.00';
    final double value = double.tryParse(amount) ?? 0;
    return value.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    final month = months[dateTime.month - 1];
    final day = dateTime.day.toString().padLeft(2, '0');
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$day $month $year - $hour:${minute}';
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$text copied to clipboard'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _shareReceipt() {
    // Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality will be implemented'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _downloadReceipt() {
    // Implement download functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Receipt download will be implemented'),
        backgroundColor: Colors.green,
      ),
    );
  }
}