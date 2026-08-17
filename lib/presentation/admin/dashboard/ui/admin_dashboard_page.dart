import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/skeletal_loader.dart';
import '../cubit/admin_dashboard_cubit.dart';
import '../cubit/admin_dashboard_state.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  late final AdminDashboardCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<AdminDashboardCubit>();
    _cubit.loadDashboard();
  }

  void _selectCustomDateRange(
    BuildContext context,
    AdminDashboardLoaded state,
  ) async {
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: state.startDate != null && state.endDate != null
          ? DateTimeRange(start: state.startDate!, end: state.endDate!)
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
      _cubit.loadDashboard(
        period: 'Custom',
        startDate: pickedRange.start,
        endDate: pickedRange.end,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
      builder: (context, state) {
        if (state is AdminDashboardLoading) {
          return _buildSkeletonLoader(context);
        } else if (state is AdminDashboardError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
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
                    'Something went wrong',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    state.message,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                    onPressed: () => _cubit.loadDashboard(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else if (state is AdminDashboardLoaded) {
          return RefreshIndicator(
            onRefresh: () => _cubit.loadDashboard(
              period: state.selectedPeriod,
              startDate: state.startDate,
              endDate: state.endDate,
            ),
            color: AppColors.primary,
            child: LayoutBuilder(
              builder: (context, mainConstraints) {
                final isMobile = mainConstraints.maxWidth < 700;
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome Banner & Date Range Row (Stacked on Mobile, Row on Desktop)
                      isMobile
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Good morning, Admin 👋',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  "Here's what's happening with your business today.",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildPeriodSelectorButton(context, state),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: const [
                                      Text(
                                        'Good morning, Admin 👋',
                                        style: TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        "Here's what's happening with your business today.",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                _buildPeriodSelectorButton(context, state),
                              ],
                            ),
                      const SizedBox(height: 24),

                      // KPI Cards Grid
                      _buildKPICards(state),
                      const SizedBox(height: 32),

                      // Central Charts Section
                      LayoutBuilder(
                        builder: (context, chartConstraints) {
                          final isCompact = chartConstraints.maxWidth < 900;

                          final chartCard = Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(
                                color: AppColors.border,
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: const [
                                          Text(
                                            'Sales Overview',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textDark,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Track your sales performance over time',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          _buildLegendIndicator(
                                            'Sales',
                                            AppColors.primary,
                                          ),
                                          const SizedBox(width: 12),
                                          _buildLegendIndicator(
                                            'Income',
                                            AppColors.success,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    height: 280,
                                    child: _AreaChart(
                                      data: state.chartDataList,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );

                          final financialSummaryCard = Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(
                                color: AppColors.border,
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Financial Overview',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Relationship between revenue, expenses and profit',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 28),
                                  _buildFinancialRow(
                                    'Total Revenue',
                                    state.todaySales,
                                    AppColors.primary,
                                    1.0,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildFinancialRow(
                                    'Total Expenses',
                                    state.todayExpenses,
                                    AppColors.error,
                                    state.todaySales > 0
                                        ? (state.todayExpenses /
                                                  state.todaySales)
                                              .clamp(0.0, 1.0)
                                        : 0.15,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildFinancialRow(
                                    'Net Income',
                                    state.todayIncome,
                                    AppColors.success,
                                    state.todaySales > 0
                                        ? (state.todayIncome / state.todaySales)
                                              .clamp(0.0, 1.0)
                                        : 0.85,
                                  ),
                                ],
                              ),
                            ),
                          );

                          if (isCompact) {
                            return Column(
                              children: [
                                chartCard,
                                const SizedBox(height: 24),
                                financialSummaryCard,
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 3, child: chartCard),
                              const SizedBox(width: 24),
                              Expanded(flex: 2, child: financialSummaryCard),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 32),

                      // Best Sellers & Recent Transactions Section
                      LayoutBuilder(
                        builder: (context, secondRowConstraints) {
                          final isCompact = secondRowConstraints.maxWidth < 900;

                          final bestSellersCard = Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(
                                color: AppColors.border,
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Top Selling Items',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  if (state.bestSellers.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 40.0,
                                      ),
                                      child: Center(
                                        child: Text(
                                          'No sales transactions in this period',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    _buildBestSellersList(state.bestSellers),
                                ],
                              ),
                            ),
                          );

                          final recentTransactionsCard = Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(
                                color: AppColors.border,
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Recent Transactions',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            context.go('/admin/reports/income'),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: const [
                                            Text(
                                              'View All',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(width: 4),
                                            Icon(
                                              Icons.arrow_forward_rounded,
                                              size: 14,
                                              color: AppColors.primary,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _buildRecentTransactionsList(),
                                ],
                              ),
                            ),
                          );

                          if (isCompact) {
                            return Column(
                              children: [
                                bestSellersCard,
                                const SizedBox(height: 24),
                                recentTransactionsCard,
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 1, child: bestSellersCard),
                              const SizedBox(width: 24),
                              Expanded(flex: 1, child: recentTransactionsCard),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSkeletonLoader(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 700;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        SkeletalLoader(width: 200, height: 24, borderRadius: 6),
                        SizedBox(height: 6),
                        SkeletalLoader(width: 250, height: 14, borderRadius: 4),
                        SizedBox(height: 12),
                        SkeletalLoader(
                          width: 110,
                          height: 38,
                          borderRadius: 10,
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            SkeletalLoader(
                              width: 240,
                              height: 28,
                              borderRadius: 6,
                            ),
                            SizedBox(height: 6),
                            SkeletalLoader(
                              width: 320,
                              height: 16,
                              borderRadius: 4,
                            ),
                          ],
                        ),
                        const SkeletalLoader(
                          width: 110,
                          height: 40,
                          borderRadius: 20,
                        ),
                      ],
                    ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, gridConstraints) {
                  final cols = gridConstraints.maxWidth < 600
                      ? 1
                      : (gridConstraints.maxWidth < 1000 ? 2 : 4);
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: cols,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: cols == 1 ? 3.2 : 1.6,
                    children: List.generate(4, (_) => SkeletalLoader.card()),
                  );
                },
              ),
              const SizedBox(height: 32),
              const SkeletalLoader(
                width: double.infinity,
                height: 320,
                borderRadius: 16,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPeriodSelectorButton(
    BuildContext context,
    AdminDashboardLoaded state,
  ) {
    String label = state.selectedPeriod;
    if (state.selectedPeriod == 'Custom' &&
        state.startDate != null &&
        state.endDate != null) {
      label =
          '${DateFormat('d/M/yy').format(state.startDate!)} - ${DateFormat('d/M/yy').format(state.endDate!)}';
    }

    return PopupMenuButton<String>(
      onSelected: (val) {
        if (val == 'Custom') {
          _selectCustomDateRange(context, state);
        } else {
          _cubit.loadDashboard(period: val);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'Today', child: Text('Today')),
        const PopupMenuItem(value: 'Yesterday', child: Text('Yesterday')),
        const PopupMenuItem(value: 'Last 7 Days', child: Text('Last 7 Days')),
        const PopupMenuItem(value: 'Last 30 Days', child: Text('Last 30 Days')),
        const PopupMenuItem(value: 'Custom', child: Text('Custom Range...')),
      ],
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 14,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 14,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPICards(AdminDashboardLoaded state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        int crossAxisCount = 4;
        if (width < 600) {
          crossAxisCount = 1;
        } else if (width < 1000) {
          crossAxisCount = 2;
        }
        final double aspect = width < 600 ? 3.0 : 1.7;

        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: aspect,
          ),
          children: [
            _buildKPICard(
              title: 'Total Revenue',
              value: CurrencyFormatter.format(state.todaySales),
              growth: '+12.5%',
              vsPeriod: 'vs last period',
              isPositive: true,
              sparkValues: [1.2, 1.4, 1.3, 1.6, 1.5, 1.7, 2.0],
              sparkColor: AppColors.primary,
            ),
            _buildKPICard(
              title: 'Total Orders',
              value: '${state.totalTransactions}',
              growth: '+8.2%',
              vsPeriod: 'vs last period',
              isPositive: true,
              sparkValues: [80.0, 95.0, 85.0, 110.0, 105.0, 120.0, 128.0],
              sparkColor: Colors.blue,
            ),
            _buildKPICard(
              title: 'Total Expenses',
              value: CurrencyFormatter.format(state.todayExpenses),
              growth: '-3.4%',
              vsPeriod: 'vs last period',
              isPositive: false,
              sparkValues: [4.8, 5.2, 4.0, 4.2, 3.8, 4.0, 3.4],
              sparkColor: AppColors.error,
            ),
            _buildKPICard(
              title: 'Net Income',
              value: CurrencyFormatter.format(state.todayIncome),
              growth: '+15.8%',
              vsPeriod: 'vs last period',
              isPositive: true,
              sparkValues: [0.8, 1.0, 0.9, 1.2, 1.1, 1.3, 1.68],
              sparkColor: AppColors.success,
            ),
          ],
        );
      },
    );
  }

  Widget _buildKPICard({
    required String title,
    required String value,
    required String growth,
    required String vsPeriod,
    required bool isPositive,
    required List<double> sparkValues,
    required Color sparkColor,
  }) {
    final Color growthColor = isPositive ? AppColors.success : AppColors.error;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        growth,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: growthColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          vsPeriod,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Mini Sparkline Graph
            SizedBox(
              width: 50,
              height: 35,
              child: CustomPaint(
                painter: _SparklinePainter(
                  values: sparkValues,
                  color: sparkColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendIndicator(String name, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          name,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialRow(
    String name,
    double amount,
    Color color,
    double percentage,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark,
              ),
            ),
            Text(
              CurrencyFormatter.format(amount),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            Container(
              height: 8,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200]!,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  height: 8,
                  width: constraints.maxWidth * percentage,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBestSellersList(List<BestSellerItem> bestSellers) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: bestSellers.length.clamp(0, 5),
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final item = bestSellers[index];
        final double maxSales = bestSellers.first.totalSales;
        final double progress = maxSales > 0
            ? (item.totalSales / maxSales)
            : 0.0;

        Widget rankWidget;
        if (index == 0) {
          rankWidget = const Text('🥇', style: TextStyle(fontSize: 18));
        } else if (index == 1) {
          rankWidget = const Text('🥈', style: TextStyle(fontSize: 18));
        } else if (index == 2) {
          rankWidget = const Text('🥉', style: TextStyle(fontSize: 18));
        } else {
          rankWidget = CircleAvatar(
            radius: 10,
            backgroundColor: Colors.grey[200],
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          );
        }

        return Row(
          children: [
            SizedBox(width: 28, child: Center(child: rankWidget)),
            const SizedBox(width: 10),
            // Mock Food Image container
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.restaurant_menu,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.menuName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        '${item.soldCount} sold',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                            minHeight: 5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        CurrencyFormatter.format(item.totalSales),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentTransactionsList() {
    final List<Map<String, dynamic>> mockTrx = [
      {
        'id': '#TRX-10284',
        'time': 'Today, 14:32',
        'amount': 125000.0,
        'method': 'QRIS',
        'status': 'Paid',
      },
      {
        'id': '#TRX-10283',
        'time': 'Today, 11:15',
        'amount': 75000.0,
        'method': 'Cash',
        'status': 'Paid',
      },
      {
        'id': '#TRX-10282',
        'time': 'Yesterday, 19:40',
        'amount': 195000.0,
        'method': 'QRIS',
        'status': 'Paid',
      },
      {
        'id': '#TRX-10281',
        'time': 'Yesterday, 17:10',
        'amount': 45000.0,
        'method': 'Cash',
        'status': 'Paid',
      },
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: mockTrx.length,
      separatorBuilder: (_, __) => const Divider(height: 20),
      itemBuilder: (context, index) {
        final trx = mockTrx[index];

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trx['id'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  trx['time'],
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.format(trx['amount']),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      trx['method'],
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Paid',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ----------------- Data Visualization Painting Widgets -----------------

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;

  _SparklinePainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final double width = size.width;
    final double height = size.height;

    double maxVal = values.reduce((curr, next) => curr > next ? curr : next);
    double minVal = values.reduce((curr, next) => curr < next ? curr : next);
    if (maxVal == minVal) {
      maxVal += 1.0;
      minVal -= 1.0;
    }
    final double range = maxVal - minVal;

    final double step = width / (values.length - 1);
    final Path path = Path();

    final double firstX = 0;
    final double firstY = height - ((values[0] - minVal) / range) * height;
    path.moveTo(firstX, firstY);

    for (int i = 0; i < values.length - 1; i++) {
      final double x1 = i * step;
      final double y1 = height - ((values[i] - minVal) / range) * height;
      final double x2 = (i + 1) * step;
      final double y2 = height - ((values[i + 1] - minVal) / range) * height;

      final double cx1 = x1 + (x2 - x1) / 2.0;
      final double cy1 = y1;
      final double cx2 = x1 + (x2 - x1) / 2.0;
      final double cy2 = y2;
      path.cubicTo(cx1, cy1, cx2, cy2, x2, y2);
    }

    final Paint linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.color != color;
  }
}

class _AreaChart extends StatefulWidget {
  final List<SalesChartData> data;

  const _AreaChart({required this.data});

  @override
  State<_AreaChart> createState() => _AreaChartState();
}

class _AreaChartState extends State<_AreaChart> {
  Offset? _hoverOffset;
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return const Center(child: Text('No chart data available'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double height = constraints.maxHeight;

        return MouseRegion(
          onHover: (event) {
            final double localX = event.localPosition.dx;
            final double chartWidth = width - 60;
            if (chartWidth <= 0) return;

            final int pointsCount = widget.data.length;
            final double step = chartWidth / (pointsCount - 1);

            final double relativeX = (localX - 45).clamp(0, chartWidth);
            final int index = (relativeX / step).round().clamp(
              0,
              pointsCount - 1,
            );

            setState(() {
              _hoverOffset = event.localPosition;
              _hoveredIndex = index;
            });
          },
          onExit: (_) {
            setState(() {
              _hoverOffset = null;
              _hoveredIndex = null;
            });
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CustomPaint(
                size: Size(width, height),
                painter: _AreaChartPainter(
                  data: widget.data,
                  hoveredIndex: _hoveredIndex,
                ),
              ),
              if (_hoveredIndex != null && _hoverOffset != null)
                _buildTooltip(width, height),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTooltip(double width, double height) {
    final item = widget.data[_hoveredIndex!];
    final double chartWidth = width - 60;
    final double step = chartWidth / (widget.data.length - 1);
    final double pointX = 45 + _hoveredIndex! * step;

    double tooltipLeft = pointX - 70;
    if (tooltipLeft < 10) tooltipLeft = 10;
    if (tooltipLeft + 140 > width) tooltipLeft = width - 150;

    return Positioned(
      left: tooltipLeft,
      top: 10,
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.grey900.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Sales: ${CurrencyFormatter.format(item.salesAmount)}',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Income: ${CurrencyFormatter.format(item.incomeAmount)}',
              style: const TextStyle(
                color: Colors.greenAccent,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Orders: ${item.transactionCount}',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _AreaChartPainter extends CustomPainter {
  final List<SalesChartData> data;
  final int? hoveredIndex;

  _AreaChartPainter({required this.data, this.hoveredIndex});

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;

    final double leftPadding = 45.0;
    final double rightPadding = 15.0;
    final double topPadding = 25.0;
    final double bottomPadding = 25.0;

    final double chartWidth = width - leftPadding - rightPadding;
    final double chartHeight = height - topPadding - bottomPadding;

    if (chartWidth <= 0 || chartHeight <= 0) return;

    double maxVal = 0.0;
    for (final d in data) {
      if (d.salesAmount > maxVal) maxVal = d.salesAmount;
      if (d.incomeAmount > maxVal) maxVal = d.incomeAmount;
    }
    if (maxVal == 0.0) maxVal = 100000.0;
    maxVal = maxVal * 1.15;

    // Grid lines and labels
    final int gridLines = 4;
    final Paint gridPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < gridLines; i++) {
      final double y = topPadding + (chartHeight / (gridLines - 1)) * i;
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(width - rightPadding, y),
        gridPaint,
      );

      final double val = maxVal - (maxVal / (gridLines - 1)) * i;
      final textSpan = TextSpan(
        text: _formatShortCurrency(val),
        style: TextStyle(
          color: Colors.grey[500],
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(leftPadding - textPainter.width - 6, y - textPainter.height / 2),
      );
    }

    // X-axis Labels
    final int pointsCount = data.length;
    final double step = chartWidth / (pointsCount - 1);

    final int xLabelInterval = (pointsCount / 5).ceil().clamp(1, pointsCount);
    for (int i = 0; i < pointsCount; i++) {
      if (i % xLabelInterval == 0 || i == pointsCount - 1) {
        final double x = leftPadding + i * step;
        final textSpan = TextSpan(
          text: data[i].label,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, height - bottomPadding + 6),
        );
      }
    }

    // Draw Curves
    _drawCurve(
      canvas,
      chartHeight,
      leftPadding,
      topPadding,
      step,
      maxVal,
      AppColors.primary,
    );
    _drawCurve(
      canvas,
      chartHeight,
      leftPadding,
      topPadding,
      step,
      maxVal,
      AppColors.success,
    );

    // Hover indicators
    if (hoveredIndex != null) {
      final double x = leftPadding + hoveredIndex! * step;
      final Paint hoverLinePaint = Paint()
        ..color = AppColors.grey400
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(x, topPadding),
        Offset(x, height - bottomPadding),
        hoverLinePaint,
      );

      final double salesY =
          height -
          bottomPadding -
          (data[hoveredIndex!].salesAmount / maxVal) * chartHeight;
      final double incomeY =
          height -
          bottomPadding -
          (data[hoveredIndex!].incomeAmount / maxVal) * chartHeight;

      // Draw point intersections
      canvas.drawCircle(
        Offset(x, salesY),
        5,
        Paint()..color = AppColors.primary,
      );
      canvas.drawCircle(
        Offset(x, salesY),
        7,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      canvas.drawCircle(
        Offset(x, incomeY),
        5,
        Paint()..color = AppColors.success,
      );
      canvas.drawCircle(
        Offset(x, incomeY),
        7,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  void _drawCurve(
    Canvas canvas,
    double chartHeight,
    double leftPadding,
    double topPadding,
    double step,
    double maxVal,
    Color color,
  ) {
    final Path path = Path();
    final Path areaPath = Path();

    final int pointsCount = data.length;
    double getVal(int i) =>
        color == AppColors.primary ? data[i].salesAmount : data[i].incomeAmount;

    final double firstX = leftPadding;
    final double firstY =
        topPadding + chartHeight - (getVal(0) / maxVal) * chartHeight;
    path.moveTo(firstX, firstY);
    areaPath.moveTo(firstX, topPadding + chartHeight);
    areaPath.lineTo(firstX, firstY);

    for (int i = 0; i < pointsCount - 1; i++) {
      final double x1 = leftPadding + i * step;
      final double y1 =
          topPadding + chartHeight - (getVal(i) / maxVal) * chartHeight;
      final double x2 = leftPadding + (i + 1) * step;
      final double y2 =
          topPadding + chartHeight - (getVal(i + 1) / maxVal) * chartHeight;

      final double cx1 = x1 + (x2 - x1) / 2.0;
      final double cy1 = y1;
      final double cx2 = x1 + (x2 - x1) / 2.0;
      final double cy2 = y2;

      path.cubicTo(cx1, cy1, cx2, cy2, x2, y2);
      areaPath.cubicTo(cx1, cy1, cx2, cy2, x2, y2);
    }

    final double lastX = leftPadding + (pointsCount - 1) * step;
    areaPath.lineTo(lastX, topPadding + chartHeight);
    areaPath.close();

    final Paint areaPaint = Paint()
      ..shader =
          LinearGradient(
            colors: [
              color.withValues(alpha: 0.15),
              color.withValues(alpha: 0.00),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(
            Rect.fromLTRB(
              leftPadding,
              topPadding,
              lastX,
              topPadding + chartHeight,
            ),
          )
      ..style = PaintingStyle.fill;
    canvas.drawPath(areaPath, areaPaint);

    final Paint linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);
  }

  String _formatShortCurrency(double val) {
    if (val >= 1000000) {
      return '${(val / 1000000).toStringAsFixed(1)}M';
    } else if (val >= 1000) {
      return '${(val / 1000).toStringAsFixed(0)}k';
    }
    return val.toStringAsFixed(0);
  }

  @override
  bool shouldRepaint(covariant _AreaChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.hoveredIndex != hoveredIndex;
  }
}
