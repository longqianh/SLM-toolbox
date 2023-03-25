%% blazed grating
close all;clc;
N=3;a=1;
T=a*N;
A=0.5;
t0=zeros(T,1);
for n=1:N
    t0((n-1)*a+1:n*a)=ones(a,1)*exp(1j*2*pi*A*(n-1)/N);
end
t0=t0/sqrt(T);

W=1920;
t=zeros(W,1);
% plot(unwrap(angle(t0)))
for l=1:floor(W/T)
    t((l-1)*T+1:l*T)=t0;
end
t(floor(W/T)*T+1:end)=t0(1:mod(W,T));
% plot((angle(t)))

I=abs(fftshift(fft(fftshift(t)))).^2;
% plot(I)
sum(I)


%% common grating
close all;clc;
N=2;a=1;
T=a*N;
x=-a/2:a/2;
A=0.2;
t0=zeros(T,1);
for n=1:N
    t0((n-1)*a+1:n*a)=ones(a,1)*exp(1j*2*pi*A*(n-1)/N);
end
t0=t0/sqrt(T);
W=1920;
t=zeros(W,1);
% plot(unwrap(angle(t0)))
for l=1:floor(W/T)
    t((l-1)*T+1:l*T)=t0;
end
t(floor(W/T)*T+1:end)=t0(1:mod(W,T));
% plot((angle(t)))

I=abs(fftshift(fft(fftshift(t)))).^2;
plot(I)
sum(I)
