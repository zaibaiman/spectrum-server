%V3:  Usamos el método Down-Hill simplex para encontrar los parámetros optimizados (k, x0)
%V2p5: Toma un conjunto de puntos y hace un ajuste no-lineal a los datos
%Un conjunto de puntos sobre la zona de los lentes es seleccionada aleatoriamente: (Xi, Yi, Zi)
%En esta version incluimos Td en los calculos
%Tc: es una funcion logistica
%Td: transmitancia difusa-.difusa


%--------------------------------------- Variables iniciales:
clear % limpamos
lambda = linspace(400, 700, 100);
cte = 0.96e-3;
x0o = 420;
ko  = 0.3;
Lo = .95;

%comentarios activados 1 y desactivados 0
com = 1;

%--- seleccionamos n puntos sobre el area de la lente
N = 1;

%--------------------------------------- Parametros de entrada (INPUT):

%--- cargamos la imagen de prueba:

I = imread ('sample.jpg');

[m,n,p] = size(I);


%--- Obtenemos las color matching functions x, y z barra

%-- cargamos x barra, y barra y z barra

load x_bar.dat;
load y_bar.dat;
load z_bar.dat;

%%---Calculo de las coordenadas RGB de puntos sobre la lente (xi, yi) y la referencia  (xp, yp)

xi = round(800+400*rand(1,N));
yi = round(200+200*(2*rand(1,N)-1));

%--- seleccionamos un punto de la periferia (x1,y1): punto "blanco"
xp = 500;
yp = 200;


%--- cordenadas RGB del punto (o pixel) (xi,yi) de la zona de la lente:
R0 = double(I(xi(1),yi(1),1));
G0 = double(I(xi(1),yi(1),2));
B0 = double(I(xi(1),yi(1),3));

Ri = double(I(xi,yi,1));
Gi = double(I(xi,yi,2));
Bi = double(I(xi,yi,3));


if com == 1,
fprintf('\nCoordenadas RGB del punto sobre la lente (R0, G0, B0) = (%d, %d,  %d)', R0, G0, B0)
end


%--- cordenadas RGB del punto (o pixel) (x0,y0) de referencia "blanco"
Rp = double(I(xp,yp,1));
Gp = double(I(xp,yp,2));
Bp = double(I(xp,yp,3));

if com == 1,
fprintf('\nCoordenadas RGB del punto de referencia (Rp, Gp, Bp) =  (%d, %d,  %d)\n', Rp, Gp, Bp)
end


%--- Convertimos las coordenadas RGB a  XYZ a traves de la matriz M

M = (1/0.17697).*[0.49 0.310 0.1; 0.17697 0.81240 0.01063; 0.0 0.010 0.99];

for i = 1: N,
X= double([Ri(i);Gi(i);Bi(i)]);
Y = M*X;
Xi(i) = Y(1);
Yi(i) = Y(2);
Zi(i) = Y(3);
end

%Tomamos el primer punto sobre la lente como referencia.

X0 = Xi(1);
Y0 = Yi(1);
Z0 = Zi(1);


%--- Hacemos la misma transformación con el punto de refencia (xp, yp):

X= double([Rp;Gp;Bp]);
Y = M*X;
X1 = Y(1);
Y1 = Y(2);
Z1 = Y(3);



%------------------- Lf ----------------------- Definimos a la radiancia espectral  "Lf" como una función cuadratica: Lf = c1*lambda.^2 + c2*lambda.^2 + c3;

%--- ajuste por minimos cuadrados:
A = [sum(lambda.^2.*x_bar), sum(lambda.^1.*x_bar) sum(lambda.^0.*x_bar);
     sum(lambda.^2.*y_bar), sum(lambda.^1.*y_bar) sum(lambda.^0.*y_bar);
     sum(lambda.^2.*z_bar), sum(lambda.^1.*z_bar) sum(lambda.^0.*z_bar)];
B = [X1;Y1;Z1]; %coordenadas del punto de referencia (blanco)

%resolvemos el sistema de 3 ecuaciones con 3 incognitas (c1, c2 y c3), método de los determinantes

C(1) = det([B,A(:,2:3)])./det(A);        %sustituimos la primer columna de A por el vector B
C(2) = det([A(:,1), B,A(:,3) ])./det(A); %sustituimos la segunda columna de A por el vector B
C(3) = det([A(:,1:2), B])./det(A);       %sustituimos la tercer columna de A por el vector B

Lf = C(1).*lambda.^2 + C(2).*lambda.^1 + C(3);
Lf = Lf./max(Lf);

% calibramos el valor de Lf para que sea consistente con las fotografias.

Lf = cte.*Lf;



%------------------------ Td ---------------------- Definimos el perfil de la transmitacia difusa Td como una funcion cuadratica: Td = c1*lambda^2 + c2*lambda + c3

%suponemos que Tc es una funcion logistica (esta suposición esta basada en resultados experimentales)

Tc = Lo./(1+exp(-ko.*(lambda-x0o)));

A = [sum(lambda.^2.*Tc.*Lf.*x_bar), sum(lambda.^1.*Tc.*Lf.*x_bar) sum(lambda.^0.*Tc.*Lf.*x_bar);
     sum(lambda.^2.*Tc.*Lf.*y_bar), sum(lambda.^1.*Tc.*Lf.*y_bar) sum(lambda.^0.*Tc.*Lf.*y_bar);
     sum(lambda.^2.*Tc.*Lf.*z_bar), sum(lambda.^1.*Tc.*Lf.*z_bar) sum(lambda.^0.*Tc.*Lf.*z_bar)];
B = [X0;Y0;Z0]; %coordenadas del punto de referencia (blanco)

%resolvemos el sistema de 3 ecuaciones con 3 incognitas (c1, c2 y c3), método de los determinantes

C(1) = det([B,A(:,2:3)])./det(A);        %sustituimos la primer columna de A por el vector B
C(2) = det([A(:,1), B,A(:,3) ])./det(A); %sustituimos la segunda columna de A por el vector B
C(3) = det([A(:,1:2), B])./det(A);       %sustituimos la tercer columna de A por el vector B

Td = C(1).*lambda.^2 + C(2).*lambda.^1 + C(3);
Td = Td./max(Td);



%--- Calculamos las coordenadas X, Y , Z del punto de referencia (blanco) (xp, yp) usando la curva espectral de radiancia Lf

X_Lf = sum(Lf.*x_bar).*(lambda(2)-lambda(1));
%--- Normalizamos con respecto al valor del pixel (x1, y1)
cte = X1/X_Lf;
Lf = cte*Lf;
X_Lf = sum(Lf.*x_bar).*(lambda(2)-lambda(1));
Y_Lf = sum(Lf.*y_bar).*(lambda(2)-lambda(1));
Z_Lf = sum(Lf.*z_bar).*(lambda(2)-lambda(1));


%comparacion de las coordenadas del punto de referencia y  las generadas con Lf:
if com == 1,
fprintf('\nComparacion de las coordenadas del punto de referencia y  las generadas con Lf:');
[X1 X_Lf;Y1 Y_Lf;Z1 Z_Lf]
end

%inverso de la matrix de tranformacion M para obtener coordenadas RGB
V = inv(M)*double([X_Lf;Y_Lf;Z_Lf]);

R_Lf = double(V(1));
G_Lf = double(V(2));
B_Lf = double(V(3));

%comparacion de las coordenadas RGB del punto de referencia y  las generadas con Lf:
if com == 1,
fprintf('\ncomparacion de las coordenadas RGB del punto de referencia y  las generadas con Lf:\n');
[Rp R_Lf;Gp G_Lf;Bp B_Lf]
end


%--- Calculamos las coordenadas X, Y , Z de los pixeles sobre la lente (xi, yi) a través de las curvas espectales: Lf y Tc


%valores promediados finales: (suponemos que son los que dimos de entrada)
L = Lo;
k = ko;
x0 = x0o;


for i = 1:1,
            %no aplicamos el ajuste
            %[L, k, x0] = ajuste_LogisticForm(lambda, x_bar, y_bar, z_bar, Xi(i), Yi(i), Zi(i),  Td,Lf,   Lo,ko,x0o);


           xyz_bar = [x_bar', y_bar', z_bar'];
           XYZ_meas = [Xi(i), Yi(i), Zi(i)];

           %no optimizamos la solución
           %look_solution(lambda, L, k, x0, xyz_bar, XYZ_meas ,  Td', Lf');



           Tc2(i,:) = L./(1+exp(-k.*(lambda-x0)));
           X_Tc2(i, 1) = sum(Tc2(i,:).*Td.*Lf.*x_bar).*(lambda(2)-lambda(1));

           X_Tc2(i,1) = sum(Tc2(i,:).*Td.*Lf.*x_bar).*(lambda(2)-lambda(1));
           Y_Tc2(i,1) = sum(Tc2(i,:).*Td.*Lf.*y_bar).*(lambda(2)-lambda(1));
           Z_Tc2(i,1) = sum(Tc2(i,:).*Td.*Lf.*z_bar).*(lambda(2)-lambda(1));

end
Tc2 = Tc';


for i = 1:N,
                  %inverso de la matrix de tranformacion M para obtener coordenadas RGB del punto de color
                  V = inv(M)*double([X_Tc2(i);Y_Tc2(i);Z_Tc2(i)]);
                  R_Tc2(i) = double(V(1));
                  G_Tc2(i) = double(V(2));
                  B_Tc2(i) = double(V(3));
end

%comparacion de las coordenadas RGB del punto de color y  las generadas con Lf y Tc:
if com == 1,
    fprintf('\ncomparacion de las coordenadas RGB del punto de color y  las generadas con Lf y Tc:\n');
    [R0 R_Tc2(1);G0 G_Tc2(1);B0 B_Tc2(1)]
end


%-------------------------------- OUTPUT:

Tc =  L./(1+exp(-k.*(lambda-x0)));

figure
plot(lambda, Tc)
print -djpg image.jpg
