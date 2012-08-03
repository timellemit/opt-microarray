figure
fig_size = ceil(sqrt(size(I, 1)));
for i=1:size(I,1)
    subplot(fig_size,fig_size,i)
    scatter(C,I(i,:),'.');
    hold on
    x = 0:(max(C)/100):max(C);
    y = A(i) * x ./ (1 + B(i) * x);
    plot(x, y,'r');
    title('');
    xlim([0 quantile(C, 0.995)]);
    ylim([0 quantile(I(i,:),0.995)]);
    box('on');
    title(['A=',num2str(A(i)),', B=',num2str(B(i))]);
end