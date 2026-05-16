import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../design/ecommerce_widgets.dart';
import '../../../../design/modern_design_system.dart';
import '../../../../models/createur/creator_appointment.dart';
import 'creator_status_chip.dart';

class CreatorAppointmentCard extends StatelessWidget {
  const CreatorAppointmentCard({
    super.key,
    required this.appointment,
    required this.onTap,
    required this.onNext,
    required this.onCancel,
    required this.onMessage,
  });

  final CreatorAppointment appointment;
  final VoidCallback onTap;
  final VoidCallback onNext;
  final VoidCallback onCancel;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    final date = appointment.date;
    final statusColor = creatorStatusColor(appointment.status);
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      elevated: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: ModernColors.canvas,
                backgroundImage:
                    appointment.clientPhoto.isEmpty
                        ? null
                        : NetworkImage(appointment.clientPhoto),
                child:
                    appointment.clientPhoto.isEmpty
                        ? const Icon(Icons.person_rounded)
                        : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.clientName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ModernColors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      date == null
                          ? 'Date à préciser'
                          : DateFormat('EEE d MMM • HH:mm', 'fr').format(date),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ModernColors.inkSoft,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              CreatorStatusChip(
                label: appointment.statusLabel,
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            appointment.reason,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: ModernColors.inkSoft),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: appointment.nextActionLabel,
                  onPressed:
                      appointment.isCancelled || appointment.isDone
                          ? null
                          : onNext,
                  expand: true,
                ),
              ),
              const SizedBox(width: 8),
              AppIconAction(
                icon: Icons.chat_bubble_outline_rounded,
                tooltip: 'Message',
                onPressed: onMessage,
              ),
              const SizedBox(width: 8),
              AppOverflowMenu(
                actions: [
                  AppOverflowAction(
                    label: 'Annuler',
                    icon: Icons.close_rounded,
                    danger: true,
                    onPressed:
                        appointment.isCancelled || appointment.isDone
                            ? null
                            : onCancel,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
