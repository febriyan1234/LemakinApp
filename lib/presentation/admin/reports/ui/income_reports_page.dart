import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' as exc;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/file_download_helper.dart'
    if (dart.library.html) '../../../../core/utils/file_download_helper_web.dart';
import '../../../../domain/entities/order.dart';
import '../cubit/admin_reports_cubit.dart';
import '../cubit/admin_reports_state.dart';

class IncomeReportsPage extends StatefulWidget {
  const IncomeReportsPage({super.key});

  @override
  State<IncomeReportsPage> createState() => _IncomeReportsPageState();
}

class _IncomeReportsPageState extends State<IncomeReportsPage> {
  late final AdminReportsCubit _cubit;

  // Pagination State
  int _currentPage = 1;
  final int _rowsPerPage = 8;

  // Export State
  bool _isExportingPdf = false;
  bool _isExportingExcel = false;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<AdminReportsCubit>();
    _cubit.fetchReports();
  }

  void _selectDateRange(BuildContext context, AdminReportsLoaded state) async {
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange:
          state.incomeStartDate != null && state.incomeEndDate != null
          ? DateTimeRange(
              start: state.incomeStartDate!,
              end: state.incomeEndDate!,
            )
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedRange != null) {
      _cubit.updateIncomeFilters(
        startDate: pickedRange.start,
        endDate: pickedRange.end,
      );
      setState(() {
        _currentPage = 1; // Reset pagination
      });
    }
  }

  void _clearDateFilters() {
    _cubit.updateIncomeFilters(startDate: null, endDate: null);
    setState(() {
      _currentPage = 1;
    });
  }

  Future<void> _exportExcel(List<OrderEntity> orders, AdminReportsLoaded state) async {
    setState(() {
      _isExportingExcel = true;
    });

    try {
      var excel = exc.Excel.createExcel();
      var sheet = excel['Sheet1'];

      // Add headers
      sheet.appendRow([
        exc.TextCellValue('Transaction ID'),
        exc.TextCellValue('Date & Time'),
        exc.TextCellValue('Customer Name'),
        exc.TextCellValue('Customer Address'),
        exc.TextCellValue('Payment Method'),
        exc.TextCellValue('Status'),
        exc.TextCellValue('Total Amount (IDR)'),
        exc.TextCellValue('Items Count'),
      ]);

      // Add data rows
      for (var order in orders) {
        final itemsCount = order.items.fold(
          0,
          (sum, item) => sum + item.quantity,
        );
        sheet.appendRow([
          exc.TextCellValue(order.id),
          exc.TextCellValue(_formatIndoDate(order.createdAt)),
          exc.TextCellValue(order.customer.name),
          exc.TextCellValue(order.customer.address),
          exc.TextCellValue(order.paymentMethod),
          exc.TextCellValue(order.status),
          exc.DoubleCellValue(order.total.toDouble()),
          exc.IntCellValue(itemsCount),
        ]);
      }

      final fileBytes = excel.save();
      if (fileBytes != null) {
        String fileName = 'lemakin_report_';
        if (state.incomeStartDate != null && state.incomeEndDate != null) {
          final start = DateFormat('yyyyMMdd').format(state.incomeStartDate!);
          final end = DateFormat('yyyyMMdd').format(state.incomeEndDate!);
          fileName += '${start}_to_$end';
        } else {
          fileName += DateFormat('yyyyMMdd').format(DateTime.now());
        }
        fileName += '.xlsx';

        if (kIsWeb) {
          downloadFile(
            Uint8List.fromList(fileBytes),
            fileName,
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          );
          return;
        }
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(fileBytes);

        await Share.shareXFiles([
          XFile(file.path),
        ], text: 'Income Report Excel');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export Excel: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExportingExcel = false;
        });
      }
    }
  }

  Future<void> _exportPdf(List<OrderEntity> orders, AdminReportsLoaded state) async {
    setState(() {
      _isExportingPdf = true;
    });

    try {
      final pdfDoc = pw.Document();

      pdfDoc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Income Report - Lemakin',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 12),
              pw.TableHelper.fromTextArray(
                headers: [
                  'ID',
                  'Date',
                  'Customer',
                  'Payment',
                  'Status',
                  'Total',
                ],
                data: orders.map((order) {
                  return [
                    order.id,
                    DateFormat('d/M/yy HH:mm').format(order.createdAt),
                    order.customer.name,
                    order.paymentMethod,
                    order.status,
                    CurrencyFormatter.format(order.total),
                  ];
                }).toList(),
                border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellAlignment: pw.Alignment.centerLeft,
              ),
            ];
          },
        ),
      );

      final fileBytes = await pdfDoc.save();
      String fileName = 'lemakin_report_';
      if (state.incomeStartDate != null && state.incomeEndDate != null) {
        final start = DateFormat('yyyyMMdd').format(state.incomeStartDate!);
        final end = DateFormat('yyyyMMdd').format(state.incomeEndDate!);
        fileName += '${start}_to_$end';
      } else {
        fileName += DateFormat('yyyyMMdd').format(DateTime.now());
      }
      fileName += '.pdf';

      if (kIsWeb) {
        downloadFile(
          fileBytes,
          fileName,
          'application/pdf',
        );
        return;
      }
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(fileBytes);

      await Share.shareXFiles([XFile(file.path)], text: 'Income Report PDF');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export PDF: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExportingPdf = false;
        });
      }
    }
  }

  String _formatIndoDate(DateTime date) {
    return DateFormat('d MMM yyyy, HH:mm', 'id').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminReportsCubit, AdminReportsState>(
      builder: (context, state) {
        if (state is AdminReportsLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        } else if (state is AdminReportsError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  state.message,
                  style: const TextStyle(color: AppColors.error, fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _cubit.fetchReports(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        } else if (state is AdminReportsLoaded) {
          // Apply filtering for current display list
          Iterable<OrderEntity> displayOrders = state.incomeOrders;

          if (state.incomePaymentStatus != 'All') {
            displayOrders = displayOrders.where(
              (o) =>
                  o.status.toLowerCase() ==
                  state.incomePaymentStatus.toLowerCase(),
            );
          }

          if (state.incomeStartDate != null) {
            final start = DateTime(
              state.incomeStartDate!.year,
              state.incomeStartDate!.month,
              state.incomeStartDate!.day,
            );
            displayOrders = displayOrders.where(
              (o) =>
                  o.createdAt.isAfter(start) ||
                  o.createdAt.isAtSameMomentAs(start),
            );
          }

          if (state.incomeEndDate != null) {
            final end = DateTime(
              state.incomeEndDate!.year,
              state.incomeEndDate!.month,
              state.incomeEndDate!.day,
              23,
              59,
              59,
            );
            displayOrders = displayOrders.where(
              (o) =>
                  o.createdAt.isBefore(end) ||
                  o.createdAt.isAtSameMomentAs(end),
            );
          }

          final ordersList = displayOrders.toList();

          // Calculate Paginated Sub-list
          final totalOrders = ordersList.length;
          final totalPages = (totalOrders / _rowsPerPage).ceil();
          final startIndex = (_currentPage - 1) * _rowsPerPage;
          var endIndex = startIndex + _rowsPerPage;
          if (endIndex > totalOrders) endIndex = totalOrders;

          final paginatedOrders = totalOrders > 0
              ? ordersList.sublist(startIndex, endIndex)
              : <OrderEntity>[];

          return RefreshIndicator(
            onRefresh: () => _cubit.refreshReports(),
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Financial Stats Cards
                  _buildReportStats(state),
                  const SizedBox(height: 24),

                  // Filter Panel & Export Actions
                  _buildFilterActionPanel(context, state, ordersList),
                  const SizedBox(height: 24),

                  // Transactions Table Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Sales Ledger',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (totalOrders == 0)
                            _buildEmptyState()
                          else ...[
                            LayoutBuilder(
                              builder: (context, constraints) {
                                return _buildLedgerList(
                                  paginatedOrders,
                                  constraints.maxWidth < 650,
                                );
                              },
                            ),
                            const SizedBox(height: 16),

                            // Pagination Controls
                            _buildPaginationControls(totalPages),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildReportStats(AdminReportsLoaded state) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 12.0),
        child: Row(
          children: [
            Expanded(
              child: _buildStatItem(
                title: 'Total Income',
                value: CurrencyFormatter.format(state.totalIncomeSum),
                icon: Icons.payments,
                color: AppColors.success,
              ),
            ),
            _buildVerticalDivider(),
            Expanded(
              child: _buildStatItem(
                title: 'Transactions',
                value: '${state.totalIncomeTransactions} orders',
                icon: Icons.shopping_basket,
                color: Colors.blue,
              ),
            ),
            _buildVerticalDivider(),
            Expanded(
              child: _buildStatItem(
                title: 'Average Value',
                value: CurrencyFormatter.format(state.averageTransactionValue),
                icon: Icons.analytics,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(height: 40, width: 1, color: Colors.grey[200]);
  }

  Widget _buildStatItem({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.08),
          radius: 18,
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildFilterActionPanel(
    BuildContext context,
    AdminReportsLoaded state,
    List<OrderEntity> orders,
  ) {
    final statusFilter = DropdownButton<String>(
      value: state.incomePaymentStatus,
      underline: const SizedBox(),
      items: const [
        DropdownMenuItem(value: 'All', child: Text('All Payments')),
        DropdownMenuItem(value: 'Success', child: Text('Success')),
        DropdownMenuItem(value: 'Pending', child: Text('Pending')),
        DropdownMenuItem(value: 'Failed', child: Text('Failed')),
      ],
      onChanged: (val) {
        if (val != null) {
          _cubit.updateIncomeFilters(paymentStatus: val);
          setState(() {
            _currentPage = 1;
          });
        }
      },
    );

    final dateRangeButton = TextButton.icon(
      onPressed: () => _selectDateRange(context, state),
      icon: const Icon(Icons.date_range, size: 16),
      label: Text(
        state.incomeStartDate == null || state.incomeEndDate == null
            ? 'Choose Date Range'
            : '${DateFormat('d/M/yy').format(state.incomeStartDate!)} - ${DateFormat('d/M/yy').format(state.incomeEndDate!)}',
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 750;

        final filtersBlock = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.filter_list,
              size: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            statusFilter,
            const SizedBox(width: 16),
            dateRangeButton,
            if (state.incomeStartDate != null)
              IconButton(
                icon: const Icon(Icons.close, size: 14, color: AppColors.error),
                tooltip: 'Clear Date Filter',
                onPressed: _clearDateFilters,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.only(left: 4),
              ),
          ],
        );

        final exportBlock = Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _isExportingExcel ? null : () => _exportExcel(orders, state),
              icon: _isExportingExcel
                  ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 1.5),
                    )
                  : const Icon(Icons.table_view, size: 14),
              label: const Text('Excel', style: TextStyle(fontSize: 12)),
            ),
            OutlinedButton.icon(
              onPressed: _isExportingPdf ? null : () => _exportPdf(orders, state),
              icon: _isExportingPdf
                  ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 1.5),
                    )
                  : const Icon(Icons.picture_as_pdf, size: 14),
              label: const Text('PDF', style: TextStyle(fontSize: 12)),
            ),
          ],
        );

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [filtersBlock, const SizedBox(height: 12), exportBlock],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [filtersBlock, exportBlock],
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    Color bg;
    if (status.toLowerCase() == 'success') {
      color = AppColors.success;
      bg = AppColors.success.withOpacity(0.1);
    } else if (status.toLowerCase() == 'pending') {
      color = AppColors.warning;
      bg = AppColors.warning.withOpacity(0.1);
    } else {
      color = AppColors.error;
      bg = AppColors.error.withOpacity(0.1);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildPaginationControls(int totalPages) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Page $_currentPage of $totalPages',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        Row(
          children: [
            GradientButton(
              onPressed: _currentPage > 1
                  ? () => setState(() {
                      _currentPage--;
                    })
                  : null,
              borderRadius: 12,
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: const Text(
                'Previous',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            GradientButton(
              onPressed: _currentPage < totalPages
                  ? () => setState(() {
                      _currentPage++;
                    })
                  : null,
              borderRadius: 12,
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: const Text(
                'Next',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(48.0),
        child: Column(
          children: [
            Icon(Icons.receipt_long, size: 48, color: AppColors.textLight),
            SizedBox(height: 16),
            Text(
              'No transactions found matching the selected filters.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLedgerList(List<OrderEntity> orders, bool isCompact) {
    if (isCompact) {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final order = orders[index];
          return InkWell(
            onTap: () => _showOrderDetailDialog(context, order),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[100]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.01),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        order.id,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.textDark,
                        ),
                      ),
                      _buildStatusBadge(order.status),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatIndoDate(order.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${order.customer.name} • ${order.customer.address}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Divider(
                    height: 24,
                    thickness: 0.5,
                    color: AppColors.grey300,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Text(
                              order.paymentMethod,
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${order.items.fold(0, (sum, item) => sum + item.quantity)} pcs',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        CurrencyFormatter.format(order.total),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
        columns: const [
          DataColumn(
            label: Text(
              'Transaction ID',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Date & Time',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Customer',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Payment Method',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Status',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          DataColumn(
            label: Text(
              'Items Count',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
        rows: orders.map((order) {
          void tapHandler() => _showOrderDetailDialog(context, order);
          return DataRow(
            cells: [
              DataCell(
                Text(
                  order.id,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                onTap: tapHandler,
              ),
              DataCell(
                Text(_formatIndoDate(order.createdAt)),
                onTap: tapHandler,
              ),
              DataCell(
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.customer.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      order.customer.address,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                onTap: tapHandler,
              ),
              DataCell(
                Text(order.paymentMethod),
                onTap: tapHandler,
              ),
              DataCell(
                _buildStatusBadge(order.status),
                onTap: tapHandler,
              ),
              DataCell(
                Text(
                  CurrencyFormatter.format(order.total),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                onTap: tapHandler,
              ),
              DataCell(
                Text(
                  '${order.items.fold(0, (sum, item) => sum + item.quantity)} pcs',
                ),
                onTap: tapHandler,
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _showOrderDetailDialog(BuildContext context, OrderEntity order) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.receipt_long, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Transaction Detail',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textSecondary),
                onPressed: () => Navigator.pop(dialogCtx),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Meta Info Row
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      children: [
                        _buildMetaRow('Transaction ID', order.id),
                        const SizedBox(height: 6),
                        _buildMetaRow('Date & Time', _formatIndoDate(order.createdAt)),
                        const SizedBox(height: 6),
                        _buildMetaRow('Payment Method', order.paymentMethod),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Status',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            _buildStatusBadge(order.status),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Customer Section
                  const Text(
                    'Customer Info',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    order.customer.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  if (order.customer.phone.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Phone: ${order.customer.phone}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    'Address: ${order.customer.address}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 12),

                  // Ordered Items
                  const Text(
                    'Ordered Menu',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: order.items.length,
                    separatorBuilder: (context, index) => const Divider(
                      height: 20,
                      color: AppColors.border,
                    ),
                    itemBuilder: (context, index) {
                      final item = order.items[index];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Item Image Thumbnail
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              item.menuItem.imageUrl,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 50,
                                height: 50,
                                color: Colors.grey[100],
                                child: const Icon(
                                  Icons.fastfood,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.menuItem.name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                if (item.selectedVariants.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Builder(
                                    builder: (context) {
                                      final Map<String, List<String>> grouped = {};
                                      item.selectedVariants.forEach((key, opt) {
                                        final name = key.contains(':') ? key.split(':').first : key;
                                        grouped.putIfAbsent(name, () => []).add(opt.name);
                                      });
                                      final text = grouped.entries
                                          .map((e) => '${e.key}: ${e.value.join(", ")}')
                                          .join(' | ');
                                      return Text(
                                        text,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                                if (item.notes != null && item.notes!.trim().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.amber[50],
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.amber[100]!),
                                    ),
                                    child: Text(
                                      'Note: "${item.notes}"',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.amber[900],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Text(
                                  '${item.quantity} x ${CurrencyFormatter.format(item.unitPrice)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            CurrencyFormatter.format(item.subtotal),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 12),

                  // Total Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Payment',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(order.total),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (confirmCtx) {
                            return AlertDialog(
                              title: const Text('Delete Order'),
                              content: Text('Are you sure you want to delete order ${order.id}?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(confirmCtx),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(confirmCtx);
                                    Navigator.pop(dialogCtx);
                                    context.read<AdminReportsCubit>().deleteOrder(order.id);
                                  },
                                  child: const Text('Delete', style: TextStyle(color: Color(0xFFE53935))),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFEBEE),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: Color(0xFFE53935),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(dialogCtx);
                        context.push('/admin/reports/income/edit', extra: order);
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8F5E9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 18,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Close', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }
}
