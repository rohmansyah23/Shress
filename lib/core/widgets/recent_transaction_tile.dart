import 'package:flutter/material.dart';
import '../../data/local/models/transaction_model.dart';
import '../constants/constants.dart';
import '../theme/app_icon_size.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../utils/format_helpers.dart';

/// Reusable & harmonized card tile for displaying recent transaction items.
class RecentTransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final String? categoryName;
  final String? businessName;
  final Widget? trailing;
  final VoidCallback? onTap;

  const RecentTransactionTile({
    super.key,
    required this.transaction,
    this.categoryName,
    this.businessName,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == AppConstants.typeIncome;
    final primaryColor = isIncome
        ? AppTheme.profitColorTheme(context)
        : AppTheme.lossColorTheme(context);

    // Judul utama:
    // 1. Jika categoryName ada -> Gunakan categoryName (contoh: "Penjualan Produk", "Operasional")
    // 2. Jika categoryName kosong & description ada -> Gunakan description
    // 3. Jika keduanya tidak ada -> Gunakan "Transaksi General"
    final String displayTitle;
    final String? descriptionSubtitle;

    final catName = categoryName?.trim();
    final desc = transaction.description?.trim();

    if (catName != null && catName.isNotEmpty) {
      displayTitle = catName;
      descriptionSubtitle = (desc != null &&
              desc.isNotEmpty &&
              desc.toLowerCase() != catName.toLowerCase())
          ? desc
          : null;
    } else if (desc != null && desc.isNotEmpty) {
      displayTitle = desc;
      descriptionSubtitle = null;
    } else {
      displayTitle = 'Transaksi General';
      descriptionSubtitle = null;
    }

    final dateStr = FormatHelpers.displayDateWithTime(
      transaction.transactionDate,
      transaction.createdAt,
    );

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
        side: BorderSide(
          color: AppTheme.outlineVariantColorTheme(context).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s12,
            vertical: AppSpacing.s10,
          ),
          child: Row(
            children: [
              // Avatar Icon Container
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
                ),
                child: Icon(
                  isIncome
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  color: primaryColor,
                  size: AppIconSize.s18,
                ),
              ),
              const SizedBox(width: AppSpacing.s12),

              // Middle Column: Business Badge, Category Name, Date & Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge Nama Bisnis (Owner view - matching history screen outline badge)
                    if (businessName != null && businessName!.trim().isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(AppRadius.s6),
                          border: Border.all(
                            color: AppTheme.outlineVariantColorTheme(context),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          businessName!,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSurfaceColorTheme(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s4),
                    ],

                    // Nama Kategori / Deskripsi (Judul Utama)
                    Text(
                      displayTitle,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurfaceColorTheme(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 2),

                    // Tanggal Transaksi & Waktu
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.onSurfaceVariantColorTheme(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Catatan / Deskripsi Subtitle (jika beda dari judul)
                    if (descriptionSubtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        descriptionSubtitle,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.onSurfaceVariantColorTheme(context)
                              .withValues(alpha: 0.8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: AppSpacing.s12),

              // Right Column: Amount & Type Tag
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    FormatHelpers.rupiah(transaction.amount),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: primaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.s4),
                    ),
                    child: Text(
                      isIncome ? 'Masuk' : 'Keluar',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.s4),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
