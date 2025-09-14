part of 'admin_dashboard.dart';

class UserDataSource extends DataGridSource {
  UserDataSource(
      this.users,
      this.onShowDetails,
      this.onEdit,
      this.onDelete,
      ) {
    buildDataGridRows();
  }

  final List<UserModel> users;
  final Function(UserModel) onShowDetails;
  final Function(UserModel) onEdit;
  final Function(UserModel) onDelete;
  List<DataGridRow> dataGridRows = [];

  void buildDataGridRows() {
    dataGridRows = users.map<DataGridRow>((user) {
      return DataGridRow(cells: [
        DataGridCell<String>(columnName: 'name', value: user.name),
        DataGridCell<String>(columnName: 'email', value: user.email),
        DataGridCell<String>(columnName: 'role', value: user.role.toUpperCase()),
        DataGridCell<Widget>(
          columnName: 'status',
          value: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: user.isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
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
            children: [
              IconButton(
                icon: Icon(Icons.remove_red_eye, size: 18, color: AppColors.primary),
                onPressed: () => onShowDetails(user),
                tooltip: 'Voir détails',
              ),
              IconButton(
                icon: Icon(Icons.edit, size: 18, color: Colors.orange),
                onPressed: () => onEdit(user),
                tooltip: 'Modifier',
              ),
              IconButton(
                icon: Icon(Icons.delete, size: 18, color: Colors.red),
                onPressed: () => onDelete(user),
                tooltip: 'Supprimer',
              ),
            ],
          ),
        ),
      ]);
    }).toList();
  }

  @override
  List<DataGridRow> get rows => dataGridRows;

  @override
  DataGridRowAdapter? buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      cells: row.getCells().map<Widget>((dataGridCell) {
        return Container(
          alignment: dataGridCell.columnName == 'actions' || dataGridCell.columnName == 'status'
              ? Alignment.center
              : Alignment.centerLeft,
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: dataGridCell.value is Widget ? dataGridCell.value : Text(
            dataGridCell.value.toString(),
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
    );
  }
}