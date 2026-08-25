import 'package:equatable/equatable.dart';
import '../../../../domain/entities/order.dart';

class BestSellerItem extends Equatable {
  final String menuName;
  final int soldCount;
  final double totalSales;

  const BestSellerItem({
    required this.menuName,
    required this.soldCount,
    required this.totalSales,
  });

  @override
  List<Object?> get props => [menuName, soldCount, totalSales];
}

class SalesChartData extends Equatable {
  final String label;
  final int transactionCount;
  final double salesAmount;
  final double incomeAmount;

  const SalesChartData({
    required this.label,
    required this.transactionCount,
    required this.salesAmount,
    required this.incomeAmount,
  });

  @override
  List<Object?> get props => [label, transactionCount, salesAmount, incomeAmount];
}

abstract class AdminDashboardState extends Equatable {
  const AdminDashboardState();

  @override
  List<Object?> get props => [];
}

class AdminDashboardInitial extends AdminDashboardState {}

class AdminDashboardLoading extends AdminDashboardState {}

class AdminDashboardLoaded extends AdminDashboardState {
  final double todaySales;
  final double todayIncome;
  final double todayExpenses;
  final int totalTransactions;
  final int activeMenus;
  final int inactiveMenus;
  final List<BestSellerItem> bestSellers;
  final List<SalesChartData> chartDataList;
  final List<OrderEntity> recentOrders;
  final String selectedPeriod;
  final DateTime? startDate;
  final DateTime? endDate;

  const AdminDashboardLoaded({
    required this.todaySales,
    required this.todayIncome,
    required this.todayExpenses,
    required this.totalTransactions,
    required this.activeMenus,
    required this.inactiveMenus,
    required this.bestSellers,
    required this.chartDataList,
    required this.recentOrders,
    required this.selectedPeriod,
    this.startDate,
    this.endDate,
  });

  AdminDashboardLoaded copyWith({
    double? todaySales,
    double? todayIncome,
    double? todayExpenses,
    int? totalTransactions,
    int? activeMenus,
    int? inactiveMenus,
    List<BestSellerItem>? bestSellers,
    List<SalesChartData>? chartDataList,
    List<OrderEntity>? recentOrders,
    String? selectedPeriod,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return AdminDashboardLoaded(
      todaySales: todaySales ?? this.todaySales,
      todayIncome: todayIncome ?? this.todayIncome,
      todayExpenses: todayExpenses ?? this.todayExpenses,
      totalTransactions: totalTransactions ?? this.totalTransactions,
      activeMenus: activeMenus ?? this.activeMenus,
      inactiveMenus: inactiveMenus ?? this.inactiveMenus,
      bestSellers: bestSellers ?? this.bestSellers,
      chartDataList: chartDataList ?? this.chartDataList,
      recentOrders: recentOrders ?? this.recentOrders,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  @override
  List<Object?> get props => [
        todaySales,
        todayIncome,
        todayExpenses,
        totalTransactions,
        activeMenus,
        inactiveMenus,
        bestSellers,
        chartDataList,
        recentOrders,
        selectedPeriod,
        startDate,
        endDate,
      ];
}

class AdminDashboardError extends AdminDashboardState {
  final String message;

  const AdminDashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
