# landflow- 상세페이지

<aside>
💡 프로젝트를 진행하며 수행했던 요구사항 중, 기능 구현이 가장 어려웠던 부분을 포스팅했습니다.

</aside>

### 요구사항

ax1에 2차원 배열을 이미지로 표시하고, 그 위에 2차원 배열에 대응하는 등고선을 Plot한다.

- 이미지
    
    ![[이력서/신혜란/landflow- 상세페이지/Untitled.png]]
    

- 이미지 + 등고선
    
    ![[이력서/신혜란/landflow- 상세페이지/Untitled 1.png]]
    

ax1의 x,y 크기와 대응하는 0배열을 만들어, 마우스로 선택한 영역에 원하는 값을 insert할 수 있는 기능.

[landflow_실행영상.mov](landflow-%20%EC%83%81%EC%84%B8%ED%8E%98%EC%9D%B4%EC%A7%80/landflow_%25E1%2584%2589%25E1%2585%25B5%25E1%2586%25AF%25E1%2584%2592%25E1%2585%25A2%25E1%2586%25BC%25E1%2584%258B%25E1%2585%25A7%25E1%2586%25BC%25E1%2584%2589%25E1%2585%25A1%25E1%2586%25BC.mov)

### 접근법

- x.y좌표가 셀과 대응하는 heatmap을 ax2에 띄워서 조작하려고 했는데, brush 기능을 지원하지 않는다.
    
    (brush: matlab에서 그래픽 객체를 선택 및 조작할 수 있는 brush 기능)
    
    ![[이력서/신혜란/landflow- 상세페이지/Untitled 2.png]]
    
- 그래서 brush를 지원하는 그래픽 함수 중, surf 함수를 채용했다.
    
    기존 ax1(이미지, 등고선)축의 x,y에 대응하고 선택한 영역의 값을 z값으로 갖는 3차원 행렬 데이터를 구현하기 위해 surf를 사용했다.
    

- 2차원 시점
    
    ![[이력서/신혜란/landflow- 상세페이지/Untitled 3.png]]
    

- 3차원 시점
    
    ![[이력서/신혜란/landflow- 상세페이지/Untitled 4.png]]
    

### 구현방법

1. app designer 해당 페이지 pannel에 ax1(이미지, 등고선), ax2(surf) 두 가지 축을 추가한다.
    
    ![[이력서/신혜란/landflow- 상세페이지/Untitled 5.png]]
    

1. ax1에 이미지와 등고선을 plot한다
    
    ![[이력서/신혜란/landflow- 상세페이지/Untitled 1.png]]
    
    ```matlab
    
    % 2차원 이미지 Plot
    imagesc(ax1,s.rgb);
    hold(ax1,'on');
    % imagesc 2차원 이미지에 대응하는 등고선을 Plot
    contourf(ax1,img, 50,'linestyle','none');
    caxis(ax1,[0 3]);
    axis(ax1,'xy','equal','tight');
    hold(ax1,'off');
    ```
    

1. ax2에 surf를 plot한다
    
    ![[이력서/신혜란/landflow- 상세페이지/Untitled 6.png]]
    
    brush 기능을 사용하기 위해 ax1의 2차원 배열과 크기가 같은 0배열을 ax2에 surf하고 플롯을 2D로 보고, 축을 XY 평면에 정렬하여 조정한다.
    
    그리고 ax1과 ax2가 정확하게 같은 위치로 겹치게 한다.
    
    ```matlab
    app.custom_data = surf(ax2,zeros(size(app.ax1_matrix')));
    view(ax2,2); axis(ax2,'xy','equal','tight'); set(ax2,'Position',ax.Position);
    caxis(ax2,[0 3]);
    hc = colorbar(ax2,'westoutside');
    set(ax,'Color','none','BackgroundColor','none'); set(ax2,'Color','none','BackgroundColor','none','Position', ax.Position);
    ```
    

1. AlphaData로 투명도 조절
    
    ![[이력서/신혜란/landflow- 상세페이지/Untitled 7.png]]
    
    ```matlab
    alphData = app.custom_data.ZData;
    set(app.custom_data,'Alphadata',alphData,'AlphaDataMapping','none');
    % 그래픽 객체의 면이 이미지나 텍스처로 채워지도록 한다.
    app.custom_data.FaceColor = 'texturemap';
    % 그래픽 객체의 면의 투명도가 이미지나 텍스처에 따라 결정되도록 한다.
    app.custom_data.FaceAlpha = 'texturemap';
    % ax2와 ax1 축을 연결하여 동일한 축 범위를 유지한다. (ax2를 확대하면 ax1도 같이 확대하기 위해)
    linkaxes([ax2 ax1],'xy');
    ```
    

1. 브러쉬 콜백함수
    
    ```matlab
    % 콜백함수 연결
    set(b,'Enable','on','ActionPostCallback',@(ohf,s) brushedDataCallback(app,app.custom_data,ohf,s));
    app.is_dragged = false;
    ```
    
    custom_data.**ZData**: 초기값은 0행렬이었다가, 사용자가 선택한 영역에 입력한 값대로 insert되는 **최종 output**
    
    custom_data.**AlphaData**: surf의 z축 투명도 데이터. 0~1사이의 값을 갖는다. 여기선 불투명하게 보이기 위해 0.5로 설정
    
    app.**prev_data:** 영역을 선택하고 실행취소를 할 수 있기 때문에 이를 위해 선택된 영역을 중간 저장하는 변수
    
    ```matlab
    % brushed 콜백 함수: 드래그의 경우 마우스를 눌렀을 때, 떼었을 때 2번 호출된다.
    function brushedDataCallback(app,data,~,~)
        set(app.Panel_apply,'visible','on');
        if app.is_dragged
            data.ZData = app.prev_data;
        end
        app.is_dragged = true;
        app.selected_data = double(logical(data.BrushData));
        app.prev_data = data.ZData;
        idx = find(app.selected_data == 1);
        data.ZData(sub2ind(size(data.ZData), idx)) = 0.5 ;
        app.custom_data.AlphaData = app.custom_data.ZData;
        app.custom_data.AlphaData(app.custom_data.AlphaData>=1) = 0.5;
    end
    ```
    
2. [apply]버튼 클릭 이벤트 콜백 함수
    
    ```matlab
    % Button pushed function: applyButton
    function applyButtonPushed(app, event)
        set(app.Panel_apply,'visible','off');
        n = app.insert_number.Value; % apply하는 숫자 값
    		for i=1:mesh_size(2)
          for j=1:mesh_size(1)
              if app.selected_data(i,j)~=0 % 선택된 영역에 입력받은 숫자 n을 insert
    						app.prev_data(i,j) = (n* app.selected_data(i,j));
              end
          end
        end    
    		app.custom_data.ZData = app.prev_data;
        app.custom_data.AlphaData = app.custom_data.ZData;
    		app.custom_data.AlphaData(app.custom_data.AlphaData>=1) = 0.5;
    ```