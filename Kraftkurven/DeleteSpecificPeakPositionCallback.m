function DeleteSpecificPeakPositionCallback(src,~,app)
%DELETESPECIFICPEAKPOSITIONCALLBACK zeigt Peak positionen an
%   Detailed explanation goes here
fig = gcf();
ax = findobj(fig,'type','axes');
SelType = fig.SelectionType;

if strcmp(SelType,'open')
    PointerPos = ax.CurrentPoint;
    [xvec,yvec] = prepareCurveData(src.XData,src.YData);
    idx = knnsearch([xvec,yvec],[PointerPos(1,1),PointerPos(1,2)]);
    src.XData(idx) = [];
    src.YData(idx) = [];
    name = split(src.DisplayName,'-');
    name = name(2);
    app.PeakPositions.(name{:})(idx,:) = [];
end
end

