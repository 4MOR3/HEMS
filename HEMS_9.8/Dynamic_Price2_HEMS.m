%动态电价下上班族节假日的最便宜用电负荷
%假定普通上班族周末全天在家，出门仅限于附近买生活用品，没有电动汽车需求，
%三餐在家食用，顺便打扫卫生，时间依旧以14点为分界点
clear;clc;close all;
load('D:\\work\matlab\HEMS\Ele_Price.mat');%导入电价
load('D:\\work\matlab\HEMS\Pho_Power.mat');%导入光伏发电功率
load('D:\\work\matlab\HEMS\Rigid_Load.mat');%导入刚性负荷
load('D:\\work\matlab\HEMS\Tem_Out.mat');%导入室外温度
load('D:\\work\matlab\HEMS\Hot_Water.mat');%导入每日热水用水量
load('D:\\work\matlab\HEMS\time.mat');%导入时间

n = 48;%将一天分成48组，半小时一组

%刚性负荷>rigid load>rl
%洗衣机>washing machine>wm 功率一般为0.5kw 每次使用时间为1.5h，调度时间为 14:00-22:00
%热水壶>thermos jug>tj 功率一般为1.5kw 每次使用时间为0.5h，调度时间为 21:00-7:00
%吸尘器>dust collector>dc 功率一般为1kw 每次使用时间为1h，调度时间为8:30-11:30
%洗碗机>dish-washing machine>dwm 功率一般为0.5kw 每次使用时间为1h，调度时间为 20:00-2:00
%消毒柜>dishinfection cabinet>dfc 功率一般为0.3kw 每次使用时间为0.5h，调度时间为 19:00-7:00
%烘干机>dryer>dy 功率一般为1.5kw 每次使用时间为1h，调度时间为 22:00-7:00
%电动汽车>electric vehicle>ev 功率一般为3kw，节假日不考虑
%电脑>personal computer>pc 0.3/0.15 高功率使用时间为3h，调度时间为15:00-22:00
%低功率调度时间为14:00-0:00
%空调>air conditioner>ac 2kw 假定当空调使用时，可以保持室内温度维持在25-27度，调度时间为全天
%热水器>water heater>wh 2.5kw 假定当热水器使用时，可以保持热水温度维持在45-55度，调度时间为7:00-0:00

% 决策变量
    % 2.1刚性负荷模型
    x_rl = Rigid_Load(2,:);
    % 2.2可转移负荷模型
    x_wm = binvar(1,n,'full');
    x_tj = binvar(1,n,'full');
    x_dc = binvar(1,n,'full');
    x_dwm = binvar(1,n,'full');
    x_dfc = binvar(1,n,'full');
    x_dy = binvar(1,n,'full');
    y_wm = binvar(1,n,'full');
    y_tj = binvar(1,n,'full');
    y_dc = binvar(1,n,'full');
    y_dwm = binvar(1,n,'full');
    y_dfc = binvar(1,n,'full');
    y_dy = binvar(1,n,'full');
    % 2.3可中断负荷模型
    %x_ev = binvar(1,n,'full');
    % 2.4可削减负荷模型
    x_pc = intvar(1,n,'full');
    % 2.5温控负荷模型
    t_ac = intvar(1,n,'full');
    t_wh = intvar(1,n,'full');

% 目标
m = x_wm*0.25+x_tj*0.75+x_dc*0.5+x_dwm*0.25+x_dfc*0.15+x_dy*0.75+x_pc*0.075;
for i = 1:n
    if i == 1
        m(1,i) = m(1,i) + abs(((t_ac(1,i)-27*exp(-0.5/(0.57*6)))/(1-exp(-0.5/(0.57*6)))-Tem_Out(1,i))/(2.9*6))*0.5;
    else
        m(1,i) = m(1,i) + abs(((t_ac(1,i)-t_ac(1,i-1)*exp(-0.5/(0.57*6)))/(1-exp(-0.5/(0.57*6)))-Tem_Out(1,i))/(2.9*6))*0.5; 
    end
end
for i = 1:n
    if Hot_Water(2,i) ~=0
        if i == 1
            m(1,i) = m(1,i) + abs(((t_wh(1,i)-27*exp(-0.5/(0.08*332)))/(1-exp(-0.5/(0.08*332)))-27-332*(Hot_Water(2,i)*0.0042*(t_wh(1,i)-27))/0.5)/(0.95*332))*0.5;
        else
            m(1,i) = m(1,i) + abs(((t_wh(1,i)-t_wh(1,i-1)*exp(-0.5/(0.08*332)))/(1-exp(-0.5/(0.08*332)))-27-332*(Hot_Water(2,i)*0.0042*(t_wh(1,i)-27))/0.5)/(0.95*332))*0.5;
        end
    end
end
z = sum(Ele_Price(3,:).*(m-Pho_Power*0.3));%考虑到家用光伏设备发电质量，需要乘上一个0.8的系数

% 约束添加
C = [];
    %洗衣机约束条件
    C = [C,sum(x_wm) == 3,sum(x_wm(1,1:16)) == 3];
    C = [C,sum(y_wm) == 1,sum(y_wm(1,1:15)) == 1];
    for i = 1:n
        if i ==1
            x_wm(1,i) = y_wm(1,i);
        elseif i == 2
            x_wm(1,i) = y_wm(1,i-1) + y_wm(1,i);
        else
            x_wm(1,i) = y_wm(1,i-2) + y_wm(1,i-1) + y_wm(1,i);
        end
    end
    %热水壶约束条件
    C = [C,sum(x_tj) == 1,sum(x_tj(1,15:34)) == 1];
    C = [C,sum(y_tj) == 1,sum(y_tj(1,15:34)) == 1];
    for i = 1:n
        x_tj(1,i) = y_tj(1,i);
    end
    %吸尘器约束条件
    C = [C,sum(x_dc) == 2,sum(x_dc(1,38:43)) == 2];
    C = [C,sum(y_dc) == 1,sum(y_dc(1,38:42)) == 1];
    x_dwm(1,1) = 0;
    for i = 2:n
        x_dwm(1,i) = y_dwm(1,i-1) + y_dwm(1,i);
    end
    %洗碗机约束条件
    C = [C,sum(x_dwm) == 2,sum(x_dwm(1,13:24)) == 2];
    C = [C,sum(y_dwm) == 1,sum(y_dwm(1,13:23)) == 1];
    x_dwm(1,1) = 0;
    for i = 2:n
        x_dwm(1,i) = y_dwm(1,i-1) + y_dwm(1,i);
    end
    %消毒柜约束条件
    C = [C,sum(x_dfc) == 1,sum(x_dfc(1,11:34)) == 1];
    C = [C,sum(y_dfc) == 1,sum(y_dfc(1,11:34)) == 1];
    for i = 1:n
        x_dfc(1,i) = y_dfc(1,i);
    end
    %烘干机约束条件
    C = [C,sum(x_dy) == 2,sum(x_dy(1,17:34)) == 2];
    C = [C,sum(y_dy) == 1,sum(y_dy(1,17:33)) == 1];
    x_dy(1,1) = 0;
    for i = 2:n
        x_dy(1,i) = y_dy(1,i-1) + y_dy(1,i);
    end
    %电脑约束条件
    for i = 1:n
        C = [C,0<=x_pc(1,i)<=2];
    end
    C = [C,20 <= sum(x_pc) <= 40,20 <= sum(x_pc(1,1:20)) <= 40];
    %空调约束条件
    for i = 1:n
        C = [C,25<=t_ac(1,i)<=27];
        if i == 1
            C = [C,abs(((t_ac(1,i)-27*exp(-0.5/(0.57*6)))/(1-exp(-0.5/(0.57*6)))-Tem_Out(1,i))/(2.9*6))<=2];
        else
            C = [C,abs(((t_ac(1,i)-t_ac(1,i-1)*exp(-0.5/(0.57*6)))/(1-exp(-0.5/(0.57*6)))-Tem_Out(1,i))/(2.9*6))<=2];
        end
    end
    %热水器约束条件 
    for i = 1:n
        if Hot_Water(2,i) ~= 0
            C = [C,45<=t_wh(1,i)<=55];
            if i == 1
                C = [C,abs(((t_wh(1,i)-27*exp(-0.5/(0.08*332)))/(1-exp(-0.5/(0.08*332)))-27-332*(Hot_Water(2,i)*0.0042*(t_wh(1,i)-27))/0.5)/(0.95*332))<=2.5];
            else
                C = [C,abs(((t_wh(1,i)-t_wh(1,i-1)*exp(-0.5/(0.08*332)))/(1-exp(-0.5/(0.08*332)))-27-332*(Hot_Water(2,i)*0.0042*(t_wh(1,i)-27))/0.5)/(0.95*332))<=2.5];
            end
        else
            C = [C,t_wh(1,i)==27];
        end
    end
    
% 参数设置
ops = sdpsettings('verbose',0,'solver','cplex');

% 求解
result  = optimize(C,z);
if result.problem== 0
    subplot(1,3,1);
    stairs(time,m+x_rl);%显示总负荷曲线
    hold on;
    stairs(time,Ele_Price(3,:));%显示实时电价
    subplot(1,3,2);
    stairs(time,t_ac);%显示室内温度
    hold on;
    stairs(time,Tem_Out);%显示室外温度
    subplot(1,3,3);
    stairs(time,t_wh);%显示热水水温
    hold on;
    stairs(time,Hot_Water(2,:));%显示用水负荷
    value(z+sum(Ele_Price(3,:).*x_rl*0.5))%显示工作日总电价
else
    disp('求解过程中出错');
    stairs(m+x_rl);
    value(z+sum(Ele_Price(3,:).*x_rl*0.5))
end