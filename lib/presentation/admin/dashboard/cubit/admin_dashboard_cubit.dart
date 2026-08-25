import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../domain/repositories/menu_repository.dart';
import '../../../../domain/repositories/expense_repository.dart';
import '../../../../domain/repositories/order_repository.dart';
import 'admin_dashboard_state.dart';
import '../../../../domain/entities/order.dart';

class AdminDashboardCubit extends Cubit<AdminDashboardState> {
  final MenuRepository menuRepository;
  final ExpenseRepository expenseRepository;
  final OrderRepository orderRepository;

  AdminDashboardCubit({
    required this.menuRepository,
    required this.expenseRepository,
    required this.orderRepository,
  }) : super(AdminDashboardInitial());

  Future<void> loadDashboard({
    String period = 'Today',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    emit(AdminDashboardLoading());
    try {
      // 1. Fetch menu counts
      final menus = await menuRepository.getMenuItems(includeInactive: true);
      final activeMenusCount = menus.where((m) => m.isActive).length;
      final inactiveMenusCount = menus.where((m) => !m.isActive).length;

      // 2. Fetch all orders & expenses
      final allOrders = await orderRepository.getOrders();
      final allExpenses = await expenseRepository.getExpenses();

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

      // 3. Compute today's cards
      final todayOrders = allOrders.where(
        (o) =>
            o.createdAt.isAfter(todayStart) && o.createdAt.isBefore(todayEnd),
      );
      final double todaySales = todayOrders.fold(
        0.0,
        (sum, o) => sum + o.total,
      );
      final double todayIncome = todayOrders
          .where((o) => o.status.toLowerCase() == 'success')
          .fold(0.0, (sum, o) => sum + o.total);

      final todayExpensesList = allExpenses.where(
        (e) => e.date.isAfter(todayStart) && e.date.isBefore(todayEnd),
      );
      final double todayExpenses = todayExpensesList.fold(
        0.0,
        (sum, e) => sum + e.amount,
      );

      // 4. Filter orders and expenses based on selected period
      DateTime filterStart = todayStart; // Default Today
      DateTime filterEnd = todayEnd;

      if (period == 'Today') {
        filterStart = todayStart;
        filterEnd = todayEnd;
      } else if (period == 'Yesterday') {
        filterStart = todayStart.subtract(const Duration(days: 1));
        filterEnd = DateTime(
          filterStart.year,
          filterStart.month,
          filterStart.day,
          23,
          59,
          59,
        );
      } else if (period == 'Last 7 Days') {
        filterStart = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 6));
        filterEnd = todayEnd;
      } else if (period == 'Last 30 Days') {
        filterStart = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 29));
        filterEnd = todayEnd;
      } else if (period == 'Custom' && startDate != null && endDate != null) {
        filterStart = DateTime(startDate.year, startDate.month, startDate.day);
        filterEnd = DateTime(
          endDate.year,
          endDate.month,
          endDate.day,
          23,
          59,
          59,
        );
      }

      final periodOrders = allOrders
          .where(
            (o) =>
                o.createdAt.isAfter(filterStart) &&
                o.createdAt.isBefore(filterEnd),
          )
          .toList();

      // 5. Aggregate Best Sellers (across selected period)
      final Map<String, _SellerAggregator> bestSellersMap = {};
      for (final order in periodOrders) {
        if (order.status.toLowerCase() == 'success') {
          for (final item in order.items) {
            final name = item.menuItem.name;
            final subtotal = item.subtotal;
            if (bestSellersMap.containsKey(name)) {
              bestSellersMap[name]!.add(item.quantity, subtotal);
            } else {
              bestSellersMap[name] = _SellerAggregator(item.quantity, subtotal);
            }
          }
        }
      }

      final bestSellersList = bestSellersMap.entries.map((entry) {
        return BestSellerItem(
          menuName: entry.key,
          soldCount: entry.value.quantity,
          totalSales: entry.value.totalPrice,
        );
      }).toList();
      bestSellersList.sort((a, b) {
        final compareSold = b.soldCount.compareTo(a.soldCount);
        if (compareSold != 0) return compareSold;
        
        final compareSales = b.totalSales.compareTo(a.totalSales);
        if (compareSales != 0) return compareSales;
        
        return a.menuName.compareTo(b.menuName);
      });
      final topBestSellers = bestSellersList.take(3).toList();

      // 6. Generate Sales Chart Data
      final List<SalesChartData> chartDataList = [];

      if (period == 'Today' || period == 'Yesterday') {
        // Group by 4-hour intervals to cover all 24 hours
        final intervals = [4, 8, 12, 16, 20, 24];
        for (final hour in intervals) {
          final hourOrders = periodOrders.where((o) {
            final h = o.createdAt.hour;
            return h >= (hour - 4) && h < hour;
          }).toList();

          final count = hourOrders.length;
          final sales = hourOrders.fold(0.0, (sum, o) => sum + o.total);
          final income = hourOrders
              .where((o) => o.status.toLowerCase() == 'success')
              .fold(0.0, (sum, o) => sum + o.total);

          chartDataList.add(
            SalesChartData(
              label: '${(hour - 4).toString().padLeft(2, '0')}:00-${hour.toString().padLeft(2, '0')}:00',
              transactionCount: count,
              salesAmount: sales,
              incomeAmount: income,
            ),
          );
        }
      } else if (period == 'Last 7 Days') {
        // Group by daily dates
        for (int i = 6; i >= 0; i--) {
          final date = DateTime(
            now.year,
            now.month,
            now.day,
          ).subtract(Duration(days: i));
          final startDay = DateTime(date.year, date.month, date.day);
          final endDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

          final dayOrders = allOrders.where(
            (o) =>
                o.createdAt.isAfter(startDay) && o.createdAt.isBefore(endDay),
          );
          final count = dayOrders.length;
          final sales = dayOrders.fold(0.0, (sum, o) => sum + o.total);
          final income = dayOrders
              .where((o) => o.status.toLowerCase() == 'success')
              .fold(0.0, (sum, o) => sum + o.total);

          chartDataList.add(
            SalesChartData(
              label: DateFormat('E, d MMM').format(date),
              transactionCount: count,
              salesAmount: sales,
              incomeAmount: income,
            ),
          );
        }
      } else {
        // Last 30 Days or Custom: Group by day/date ranges, or daily list up to 8 intervals to avoid crowded UI
        final int totalDays = filterEnd.difference(filterStart).inDays + 1;

        if (totalDays <= 10) {
          // Individual days
          for (int i = 0; i < totalDays; i++) {
            final date = filterStart.add(Duration(days: i));
            final startDay = DateTime(date.year, date.month, date.day);
            final endDay = DateTime(
              date.year,
              date.month,
              date.day,
              23,
              59,
              59,
            );

            final dayOrders = allOrders.where(
              (o) =>
                  o.createdAt.isAfter(startDay) && o.createdAt.isBefore(endDay),
            );
            final count = dayOrders.length;
            final sales = dayOrders.fold(0.0, (sum, o) => sum + o.total);
            final income = dayOrders
                .where((o) => o.status.toLowerCase() == 'success')
                .fold(0.0, (sum, o) => sum + o.total);

            chartDataList.add(
              SalesChartData(
                label: DateFormat('d/M').format(date),
                transactionCount: count,
                salesAmount: sales,
                incomeAmount: income,
              ),
            );
          }
        } else {
          // Chunk into 6 intervals
          final int chunkSize = (totalDays / 6).ceil();
          for (int i = 0; i < 6; i++) {
            final chunkStart = filterStart.add(Duration(days: i * chunkSize));
            var chunkEnd = chunkStart.add(Duration(days: chunkSize - 1));
            if (chunkEnd.isAfter(filterEnd)) chunkEnd = filterEnd;

            final startInterval = DateTime(
              chunkStart.year,
              chunkStart.month,
              chunkStart.day,
            );
            final endInterval = DateTime(
              chunkEnd.year,
              chunkEnd.month,
              chunkEnd.day,
              23,
              59,
              59,
            );

            final chunkOrders = allOrders.where(
              (o) =>
                  o.createdAt.isAfter(startInterval) &&
                  o.createdAt.isBefore(endInterval),
            );
            final count = chunkOrders.length;
            final sales = chunkOrders.fold(0.0, (sum, o) => sum + o.total);
            final income = chunkOrders
                .where((o) => o.status.toLowerCase() == 'success')
                .fold(0.0, (sum, o) => sum + o.total);

            final startLabel = DateFormat('d/M').format(chunkStart);
            final endLabel = DateFormat('d/M').format(chunkEnd);

            chartDataList.add(
              SalesChartData(
                label: startLabel == endLabel
                    ? startLabel
                    : '$startLabel-$endLabel',
                transactionCount: count,
                salesAmount: sales,
                incomeAmount: income,
              ),
            );
          }
        }
      }

      final sortedOrders = List<OrderEntity>.from(periodOrders);
      sortedOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final recentOrders = sortedOrders.take(4).toList();

      emit(
        AdminDashboardLoaded(
          todaySales: todaySales,
          todayIncome: todayIncome,
          todayExpenses: todayExpenses,
          totalTransactions: periodOrders.length,
          activeMenus: activeMenusCount,
          inactiveMenus: inactiveMenusCount,
          bestSellers: topBestSellers,
          chartDataList: chartDataList,
          recentOrders: recentOrders,
          selectedPeriod: period,
          startDate: startDate,
          endDate: endDate,
        ),
      );
    } catch (e) {
      emit(AdminDashboardError(e.toString()));
    }
  }
}

class _SellerAggregator {
  int quantity;
  double totalPrice;

  _SellerAggregator(this.quantity, this.totalPrice);

  void add(int qty, double price) {
    quantity += qty;
    totalPrice += price;
  }
}
