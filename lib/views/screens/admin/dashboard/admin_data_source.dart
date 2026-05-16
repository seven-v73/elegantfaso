part of 'admin_dashboard.dart';

class UserDataSource extends DataGridSource {
  UserDataSource(this.users, this.onShowDetails, this.onEdit, this.onDelete) {
    buildDataGridRows();
  }

  final List<UserModel> users;
  final Function(UserModel) onShowDetails;
  final Function(UserModel) onEdit;
  final Function(UserModel) onDelete;
  List<DataGridRow> dataGridRows = [];

  void buildDataGridRows() {
    dataGridRows =
        users.map<DataGridRow>((user) {
          return DataGridRow(
            cells: [
              DataGridCell<String>(columnName: 'name', value: user.name),
              DataGridCell<String>(columnName: 'email', value: user.email),
              DataGridCell<String>(
                columnName: 'role',
                value: user.role.toUpperCase(),
              ),
              DataGridCell<String>(columnName: 'source', value: user.source),
              DataGridCell<Widget>(
                columnName: 'status',
                value: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        user.isActive
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user.isActive ? 'ACTIF' : 'INACTIF',
                    style: TextStyle(
                      color: user.isActive ? Colors.green : Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              DataGridCell<Widget>(
                columnName: 'actions',
                value: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _AdminGridActionButton(
                      icon: Icons.remove_red_eye_rounded,
                      color: AppColors.primary,
                      tooltip: 'Voir détails',
                      onPressed: () => onShowDetails(user),
                    ),
                    _AdminGridActionButton(
                      icon: Icons.edit_rounded,
                      color: Colors.orange,
                      tooltip: 'Modifier',
                      onPressed: () => onEdit(user),
                    ),
                    _AdminGridActionButton(
                      icon: Icons.delete_rounded,
                      color: Colors.red,
                      tooltip: 'Supprimer',
                      onPressed: () => onDelete(user),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList();
  }

  @override
  List<DataGridRow> get rows => dataGridRows;

  @override
  DataGridRowAdapter? buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      cells:
          row.getCells().map<Widget>((dataGridCell) {
            return Container(
              alignment:
                  dataGridCell.columnName == 'actions' ||
                          dataGridCell.columnName == 'status'
                      ? Alignment.center
                      : Alignment.centerLeft,
              padding: EdgeInsets.symmetric(
                horizontal: dataGridCell.columnName == 'actions' ? 4 : 16,
              ),
              child:
                  dataGridCell.value is Widget
                      ? dataGridCell.value
                      : Text(
                        dataGridCell.value.toString(),
                        style: TextStyle(color: Colors.grey[800], fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
            );
          }).toList(),
    );
  }
}

class _AdminGridActionButton extends StatelessWidget {
  const _AdminGridActionButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        icon: Icon(icon, size: 17, color: color),
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 34, height: 34),
        style: IconButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}
