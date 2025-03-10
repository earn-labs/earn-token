import matplotlib.pyplot as plt

# Data
transfers = [128, 256, 512, 768, 1024]
accounts_data = {
    100: [49, 49, 52, 49, 48],
    200: [117, 101, 97, 103, 101],
    400: [219, 214, 173, 200, 203],
    800: [554, 612, 420, 445, 383],
    1600: [1172, 1304, 964, 627, 871]
}

# Plot setup
plt.figure(figsize=(10, 6))
colors = ['#1f77b4', '#ff7f0e', '#2ca02c', '#d62728', '#9467bd']  # Distinct colors
markers = ['o', 's', '^', 'D', '*']  # Distinct markers

# Plot each account series
for (accounts, errors), color, marker in zip(accounts_data.items(), colors, markers):
    plt.plot(transfers, errors, label=f'{accounts} Accounts', color=color, marker=marker, linestyle='-', linewidth=2, markersize=8)

# Highlight peak error for 1600 accounts
peak_transfers = 256
peak_error = 1304
plt.annotate(f'Peak: {peak_error}', xy=(peak_transfers, peak_error), xytext=(peak_transfers + 50, peak_error + 50),
             arrowprops=dict(facecolor='black', shrink=0.05), fontsize=10)

# Customize plot
plt.title('Rounding Error vs. Number of Transfers for Different Account Counts', fontsize=14, pad=15)
plt.xlabel('Number of Transfers', fontsize=12)
plt.ylabel('Rounding Error (wei)', fontsize=12)
plt.legend(title='Account Count', fontsize=10, title_fontsize=12)
plt.grid(True, linestyle='--', alpha=0.7)

# Optional: Logarithmic Y-axis (uncomment if desired)
# plt.yscale('log')
# plt.ylabel('Rounding Error (wei, log scale)', fontsize=12)

# Show plot
plt.tight_layout()
plt.show()