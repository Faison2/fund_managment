import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/bloc.dart';
import '../bloc/event.dart';
import '../bloc/state.dart';
import '../model/model.dart';
import '../repository/repository.dart';

class FundsScreen extends StatelessWidget {
  const FundsScreen({Key? key}) : super(key: key);

  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;

    switch (status.toLowerCase()) {
      case 'active':
      case 'available':
      case 'open':
        return Colors.green.shade600;
      case 'pending':
      case 'processing':
        return Colors.orange.shade700;
      case 'closed':
      case 'inactive':
      case 'suspended':
        return Colors.red.shade600;
      case 'paused':
      case 'maintenance':
        return Colors.blue.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  Widget _buildFundCard(Fund fund) {
    final status = fund.status ?? "Unknown";

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF81C784), Color(0xFFB2DFDB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              fund.fundingName ?? "",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Code: ${fund.fundingCode ?? 'N/A'}",
              style: const TextStyle(color: Colors.white70),
            ),
            Text(
              "Issuer: ${fund.issuer ?? 'N/A'}",
              style: const TextStyle(color: Colors.white70),
            ),
            Text(
              "Description: ${fund.description ?? 'N/A'}",
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Status Display - Not clickable, just informational
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getStatusColor(status),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _getStatusColor(status),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        status,
                        style: TextStyle(
                          color: _getStatusColor(status),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Units Display
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${fund.units ?? 0} Units",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FundsBloc(
        fundsRepository: FundsRepository(),
      )..add(const LoadFunds()),
      child: Scaffold(
        backgroundColor: const Color(0xFFB8E6D3),
        appBar: AppBar(
          title: const Text(
            "Available Funds",
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFFB8E6D3),
          actions: [
            BlocBuilder<FundsBloc, FundsState>(
              builder: (context, state) {
                return IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: () {
                    context.read<FundsBloc>().add(const RefreshFunds());
                  },
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: BlocBuilder<FundsBloc, FundsState>(
            builder: (context, state) {
              if (state is FundsLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.green),
                );
              } else if (state is FundsError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Error: ${state.message}",
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.read<FundsBloc>().add(const LoadFunds());
                        },
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                );
              } else if (state is FundsLoaded) {
                if (state.funds.isEmpty) {
                  return const Center(
                    child: Text("No funds available."),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<FundsBloc>().add(const RefreshFunds());
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: state.funds.length,
                    itemBuilder: (context, index) {
                      return _buildFundCard(state.funds[index]);
                    },
                  ),
                );
              }

              return const Center(
                child: Text("Welcome! Tap refresh to load funds."),
              );
            },
          ),
        ),
      ),
    );
  }
}