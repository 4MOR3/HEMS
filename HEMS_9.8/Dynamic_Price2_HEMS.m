%��̬������ϰ���ڼ��յ�������õ縺��
%�ٶ���ͨ�ϰ�����ĩȫ���ڼң����Ž����ڸ�����������Ʒ��û�е綯��������
%�����ڼ�ʳ�ã�˳���ɨ������ʱ��������14��Ϊ�ֽ��
clear;clc;close all;
load('D:\\work\matlab\HEMS\Ele_Price.mat');%������
load('D:\\work\matlab\HEMS\Pho_Power.mat');%���������繦��
load('D:\\work\matlab\HEMS\Rigid_Load.mat');%������Ը���
load('D:\\work\matlab\HEMS\Tem_Out.mat');%���������¶�
load('D:\\work\matlab\HEMS\Hot_Water.mat');%����ÿ����ˮ��ˮ��
load('D:\\work\matlab\HEMS\time.mat');%����ʱ��

n = 48;%��һ��ֳ�48�飬��Сʱһ��

%���Ը���>rigid load>rl
%ϴ�»�>washing machine>wm ����һ��Ϊ0.5kw ÿ��ʹ��ʱ��Ϊ1.5h������ʱ��Ϊ 14:00-22:00
%��ˮ��>thermos jug>tj ����һ��Ϊ1.5kw ÿ��ʹ��ʱ��Ϊ0.5h������ʱ��Ϊ 21:00-7:00
%������>dust collector>dc ����һ��Ϊ1kw ÿ��ʹ��ʱ��Ϊ1h������ʱ��Ϊ8:30-11:30
%ϴ���>dish-washing machine>dwm ����һ��Ϊ0.5kw ÿ��ʹ��ʱ��Ϊ1h������ʱ��Ϊ 20:00-2:00
%������>dishinfection cabinet>dfc ����һ��Ϊ0.3kw ÿ��ʹ��ʱ��Ϊ0.5h������ʱ��Ϊ 19:00-7:00
%��ɻ�>dryer>dy ����һ��Ϊ1.5kw ÿ��ʹ��ʱ��Ϊ1h������ʱ��Ϊ 22:00-7:00
%�綯����>electric vehicle>ev ����һ��Ϊ3kw���ڼ��ղ�����
%����>personal computer>pc 0.3/0.15 �߹���ʹ��ʱ��Ϊ3h������ʱ��Ϊ15:00-22:00
%�͹��ʵ���ʱ��Ϊ14:00-0:00
%�յ�>air conditioner>ac 2kw �ٶ����յ�ʹ��ʱ�����Ա��������¶�ά����25-27�ȣ�����ʱ��Ϊȫ��
%��ˮ��>water heater>wh 2.5kw �ٶ�����ˮ��ʹ��ʱ�����Ա�����ˮ�¶�ά����45-55�ȣ�����ʱ��Ϊ7:00-0:00

% ���߱���
    % 2.1���Ը���ģ��
    x_rl = Rigid_Load(2,:);
    % 2.2��ת�Ƹ���ģ��
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
    % 2.3���жϸ���ģ��
    %x_ev = binvar(1,n,'full');
    % 2.4����������ģ��
    x_pc = intvar(1,n,'full');
    % 2.5�¿ظ���ģ��
    t_ac = intvar(1,n,'full');
    t_wh = intvar(1,n,'full');

% Ŀ��
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
z = sum(Ele_Price(3,:).*(m-Pho_Power*0.3));%���ǵ����ù���豸������������Ҫ����һ��0.8��ϵ��

% Լ�����
C = [];
    %ϴ�»�Լ������
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
    %��ˮ��Լ������
    C = [C,sum(x_tj) == 1,sum(x_tj(1,15:34)) == 1];
    C = [C,sum(y_tj) == 1,sum(y_tj(1,15:34)) == 1];
    for i = 1:n
        x_tj(1,i) = y_tj(1,i);
    end
    %������Լ������
    C = [C,sum(x_dc) == 2,sum(x_dc(1,38:43)) == 2];
    C = [C,sum(y_dc) == 1,sum(y_dc(1,38:42)) == 1];
    x_dwm(1,1) = 0;
    for i = 2:n
        x_dwm(1,i) = y_dwm(1,i-1) + y_dwm(1,i);
    end
    %ϴ���Լ������
    C = [C,sum(x_dwm) == 2,sum(x_dwm(1,13:24)) == 2];
    C = [C,sum(y_dwm) == 1,sum(y_dwm(1,13:23)) == 1];
    x_dwm(1,1) = 0;
    for i = 2:n
        x_dwm(1,i) = y_dwm(1,i-1) + y_dwm(1,i);
    end
    %������Լ������
    C = [C,sum(x_dfc) == 1,sum(x_dfc(1,11:34)) == 1];
    C = [C,sum(y_dfc) == 1,sum(y_dfc(1,11:34)) == 1];
    for i = 1:n
        x_dfc(1,i) = y_dfc(1,i);
    end
    %��ɻ�Լ������
    C = [C,sum(x_dy) == 2,sum(x_dy(1,17:34)) == 2];
    C = [C,sum(y_dy) == 1,sum(y_dy(1,17:33)) == 1];
    x_dy(1,1) = 0;
    for i = 2:n
        x_dy(1,i) = y_dy(1,i-1) + y_dy(1,i);
    end
    %����Լ������
    for i = 1:n
        C = [C,0<=x_pc(1,i)<=2];
    end
    C = [C,20 <= sum(x_pc) <= 40,20 <= sum(x_pc(1,1:20)) <= 40];
    %�յ�Լ������
    for i = 1:n
        C = [C,25<=t_ac(1,i)<=27];
        if i == 1
            C = [C,abs(((t_ac(1,i)-27*exp(-0.5/(0.57*6)))/(1-exp(-0.5/(0.57*6)))-Tem_Out(1,i))/(2.9*6))<=2];
        else
            C = [C,abs(((t_ac(1,i)-t_ac(1,i-1)*exp(-0.5/(0.57*6)))/(1-exp(-0.5/(0.57*6)))-Tem_Out(1,i))/(2.9*6))<=2];
        end
    end
    %��ˮ��Լ������ 
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
    
% ��������
ops = sdpsettings('verbose',0,'solver','cplex');

% ���
result  = optimize(C,z);
if result.problem== 0
    subplot(1,3,1);
    stairs(time,m+x_rl);%��ʾ�ܸ�������
    hold on;
    stairs(time,Ele_Price(3,:));%��ʾʵʱ���
    subplot(1,3,2);
    stairs(time,t_ac);%��ʾ�����¶�
    hold on;
    stairs(time,Tem_Out);%��ʾ�����¶�
    subplot(1,3,3);
    stairs(time,t_wh);%��ʾ��ˮˮ��
    hold on;
    stairs(time,Hot_Water(2,:));%��ʾ��ˮ����
    value(z+sum(Ele_Price(3,:).*x_rl*0.5))%��ʾ�������ܵ��
else
    disp('�������г���');
    stairs(m+x_rl);
    value(z+sum(Ele_Price(3,:).*x_rl*0.5))
end