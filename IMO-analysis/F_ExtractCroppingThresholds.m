function [mov_threshold, edge_threshold] = ...
    F_ExtractCroppingThresholds(mov_scores, edge_pixels, n_gaussians)

% Computes the thresholds for movement and edge number outliers
% These are then used to crop out homecage and strapping/release periods.

% Fitting the gaussians
subplot(2, 1, 1)
mov_model = F_FitGauss(mov_scores, strcat('gauss', num2str(n_gaussians)));
xlabel("Movement score - Proxi for movement and release/strapping")

subplot(2, 1, 2)
edge_model = F_FitGauss(edge_pixels, strcat('gauss', num2str(1)));
xlabel("Edge pixels (probability) - Proxi for homecage periods")

% Gathering the coefficients
mov_coffs = coeffvalues(mov_model);
edge_coffs = coeffvalues(edge_model);

% And computing the thresholds
last_gauss = mov_coffs(end-2:end);
mov_threshold = last_gauss(2)+1.9*last_gauss(end)*sqrt(2);
last_gauss = edge_coffs(end-2:end);
edge_threshold = last_gauss(2)+1.9*last_gauss(end)*sqrt(2);

% Visualising the thresholds
subplot(2, 1, 1)
hold on
xline(mov_threshold, 'Color', 'r', 'LineWidth', 3, 'LineStyle', ":")
hold off
legnd = string({gca().Legend.String{:}});
legend(["", "", legnd(1:end-1), "Threshold"])

subplot(2, 1, 2)
hold on
xline(edge_threshold, 'Color', 'r', 'LineWidth', 3, 'LineStyle', ":")
hold off
legnd = string({gca().Legend.String{:}});
legend(["", "", legnd(1:end-1), "Threshold"])
set(gcf,'position',[400, 40, 1300, 800])
end

