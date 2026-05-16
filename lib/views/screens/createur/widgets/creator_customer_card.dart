import 'package:flutter/material.dart';

import '../../../../design/ecommerce_widgets.dart';
import '../../../../design/modern_design_system.dart';
import '../../../../models/createur/creator_customer.dart';
import 'creator_status_chip.dart';

class CreatorCustomerCard extends StatelessWidget {
  const CreatorCustomerCard({
    super.key,
    required this.customer,
    required this.onMessage,
    required this.onAppointment,
    required this.onDetails,
  });

  final CreatorCustomer customer;
  final VoidCallback onMessage;
  final VoidCallback onAppointment;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onDetails,
      padding: const EdgeInsets.all(14),
      elevated: false,
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: ModernColors.canvas,
            backgroundImage:
                customer.photoUrl.isEmpty
                    ? null
                    : NetworkImage(customer.photoUrl),
            child:
                customer.photoUrl.isEmpty
                    ? const Icon(
                      Icons.person_rounded,
                      color: ModernColors.creator,
                    )
                    : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ModernColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  customer.appointmentsCount > 0
                      ? '${customer.appointmentsCount} RDV'
                      : customer.typeLabel == 'Abonné'
                      ? 'À relancer'
                      : customer.typeLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ModernColors.inkSoft,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    CreatorStatusChip(
                      label: customer.typeLabel,
                      color: ModernColors.creator,
                    ),
                    if (customer.appointmentsCount > 0)
                      CreatorStatusChip(
                        label: '${customer.appointmentsCount} RDV',
                        color: ModernColors.client,
                      ),
                    if (customer.hasMeasurements)
                      const CreatorStatusChip(
                        label: 'Mensurations',
                        color: ModernColors.primary,
                        icon: Icons.straighten_rounded,
                      ),
                  ],
                ),
              ],
            ),
          ),
          AppIconAction(
            icon: Icons.chat_bubble_outline_rounded,
            tooltip: 'Message',
            onPressed: onMessage,
          ),
          const SizedBox(width: 6),
          AppIconAction(
            icon: Icons.event_available_rounded,
            tooltip: 'RDV',
            onPressed: onAppointment,
          ),
        ],
      ),
    );
  }
}
