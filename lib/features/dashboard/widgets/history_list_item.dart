import 'package:flutter/material.dart';
import '../../../core/models/patient_data.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/helpers.dart';

class HistoryListItem extends StatelessWidget {
  final PatientData patientData;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onResend;

  const HistoryListItem({
    super.key,
    required this.patientData,
    this.onDelete,
    this.onEdit,
    this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: InkWell(
        onTap: () => _showDetailDialog(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Icon(
                      patientData.jenisKelamin?.toUpperCase() == 'LAKI-LAKI'
                          ? Icons.person
                          : Icons.person_outline,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMedium),
                  
                  // Name and NIK
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patientData.nama ?? 'Tidak ada nama',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.badge,
                              size: 14,
                              color: AppTheme.textSecondaryColor,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                patientData.nik != null
                                    ? Helpers.formatNik(patientData.nik!)
                                    : 'NIK tidak tersedia',
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Status Badge
                        _buildStatusBadge(),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: AppTheme.spacingSmall),
                  
                  // Delete Button (always visible)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: AppTheme.errorColor,
                    onPressed: onDelete,
                    tooltip: 'Hapus',
                  ),
                ],
              ),
              
              const SizedBox(height: AppTheme.spacingSmall),
              const Divider(),
              const SizedBox(height: AppTheme.spacingSmall),
              
              // Details
              _buildInfoRow(
                context,
                Icons.cake,
                'Lahir',
                '${patientData.tempatLahir ?? '-'}, ${patientData.tanggalLahir ?? '-'}',
              ),
              const SizedBox(height: AppTheme.spacingSmall),
              _buildInfoRow(
                context,
                Icons.location_on,
                'Alamat',
                patientData.alamat ?? '-',
              ),
              const SizedBox(height: AppTheme.spacingSmall),
              _buildInfoRow(
                context,
                Icons.access_time,
                'Scan',
                patientData.scannedAt != null
                    ? Helpers.formatDateTime(patientData.scannedAt!)
                    : '-',
              ),
              
              // Action Buttons untuk pasien belum terdaftar
              if (!patientData.isRegistered) ...[
                const SizedBox(height: AppTheme.spacingMedium),
                const Divider(),
                const SizedBox(height: AppTheme.spacingSmall),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 12,
                          ),
                          side: const BorderSide(color: AppTheme.primaryColor),
                          foregroundColor: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingSmall),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onResend,
                        icon: const Icon(Icons.send, size: 18),
                        label: const Text('Kirim'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 12,
                          ),
                          backgroundColor: AppTheme.successColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: patientData.isRegistered
            ? const Color(0xFFE8F5E9) // Light green
            : const Color(0xFFFFF9C4), // Light yellow
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            patientData.isRegistered
                ? Icons.check_circle
                : Icons.pending,
            size: 14,
            color: patientData.isRegistered
                ? const Color(0xFF4CAF50) // Green
                : const Color(0xFFFFA726), // Orange/Yellow
          ),
          const SizedBox(width: 4),
          Text(
            patientData.isRegistered ? 'Terdaftar' : 'Belum Terdaftar',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: patientData.isRegistered
                  ? const Color(0xFF2E7D32) // Dark green
                  : const Color(0xFFF57C00), // Dark orange
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 11,
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDetailDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.person, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            const Expanded(child: Text('Detail Pasien')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailItem('NIK', patientData.nik ?? '-'),
              _buildDetailItem('Nama', patientData.nama ?? '-'),
              _buildDetailItem('Tempat Lahir', patientData.tempatLahir ?? '-'),
              _buildDetailItem('Tanggal Lahir', patientData.tanggalLahir ?? '-'),
              _buildDetailItem('Jenis Kelamin', patientData.jenisKelamin ?? '-'),
              _buildDetailItem('Alamat', patientData.alamat ?? '-'),
              _buildDetailItem('RT/RW', patientData.rtRw ?? '-'),
              _buildDetailItem('Kel/Desa', patientData.kelDesa ?? '-'),
              _buildDetailItem('Kecamatan', patientData.kecamatan ?? '-'),
              _buildDetailItem('Agama', patientData.agama ?? '-'),
              _buildDetailItem('Status Perkawinan', patientData.statusPerkawinan ?? '-'),
              _buildDetailItem('Pekerjaan', patientData.pekerjaan ?? '-'),
              if (patientData.scannedAt != null)
                _buildDetailItem(
                  'Waktu Scan',
                  Helpers.formatDateTime(patientData.scannedAt!),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
