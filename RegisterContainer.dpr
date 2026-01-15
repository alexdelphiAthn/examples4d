program Project2;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Spring.Collections,
  Spring.Container,
  Spring;

type
  IDiscountStrategy = interface
    ['{A74DBF88-A791-448D-B5C1-D7B05672746E}']
    function ApplyDiscount(Amount: Double): Double;
  end;

  TVIPDiscount = class(TInterfacedObject, IDiscountStrategy)
  public
    function ApplyDiscount(Amount: Double): Double; // Ejemplo: 10% menos
  end;
  TSeasonalDiscount = class(TInterfacedObject, IDiscountStrategy)
  public
    function ApplyDiscount(Amount: Double): Double; // Ejemplo: 5€ menos
  end;

  TPriceCalculator = class
  private
    FDiscounts: IList<IDiscountStrategy>;
  public
    // Spring4D inyectará automáticamente todas las IDiscountStrategy registradas aquí
    constructor Create(const Discounts: IList<IDiscountStrategy>);
    function CalculateFinalPrice(BasePrice: Double): Double;
  end;

{ TVIPDiscount }

function TVIPDiscount.ApplyDiscount(Amount: Double): Double;
begin
  Result := Amount * 0.9;
end;

{ TSeasonalDiscount }

function TSeasonalDiscount.ApplyDiscount(Amount: Double): Double;
begin
  if (Amount > 10) then
    Result := Amount - 5
  else
    Result := Amount;
end;

{ TPriceCalculator }

function TPriceCalculator.CalculateFinalPrice(BasePrice: Double): Double;
var
  descuento: IDiscountStrategy;
begin
  Result := BasePrice;
  for descuento in FDiscounts do
  begin
    Result := descuento.ApplyDiscount(Result);
  end;
end;

constructor TPriceCalculator.Create(const Discounts: IList<IDiscountStrategy>);
begin
  FDiscounts := Discounts;
end;

var
  dPrice:Double;
begin
  try
    GlobalContainer.RegisterType<TVIPDiscount>.
                               Implements<IDiscountStrategy>('VIP').AsSingleton;
    GlobalContainer.RegisterType<TSeasonalDiscount>.
                          Implements<IDiscountStrategy>('Seasonal').AsSingleton;
    GlobalContainer.Build;
    // Luego resuelve manualmente por nombre
    var strategiesList := TCollections.CreateList<IDiscountStrategy>;
    strategiesList.Add(GlobalContainer.Resolve<IDiscountStrategy>('VIP'));
    strategiesList.Add(GlobalContainer.Resolve<IDiscountStrategy>('Seasonal'));
    var calculator := TPriceCalculator.Create(strategiesList);
    Writeln('Introduce el precio a cobrar');
    Readln(dPrice);
    writeln('El precio con descuento es ' +
                            FloatToStr(calculator.CalculateFinalPrice(dPrice)));
    readln;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.

(* Ejercicio: "Sistema de Descuentos Dinámico"

El escenario: Tienes una tienda online. Dependiendo del tipo de cliente o del
              día, se pueden aplicar múltiples descuentos acumulables (un
              descuento por cupón, un descuento por ser cliente VIP,
              un descuento por rebajas de temporada).
1. El Objetivo

Crear un motor de cálculo que no conozca las reglas de descuento específicas,
sino que simplemente aplique todas las que estén registradas en el contenedor de
Spring4D.

Implementar las clases: Escribe la lógica de ApplyDiscount para cada estrategia.

Configurar el Contenedor: En el Initialization o en el punto de entrada de tu
app, registra las implementaciones:

   Usa GlobalContainer.RegisterType<TVIPDiscount>.Implements<IDiscountStrategy>;

   Registra también la otra estrategia.

   Registra el TPriceCalculator.

Probar el Motor: Pide al contenedor una instancia de TPriceCalculator
y verifica que, al llamar a CalculateFinalPrice, se apliquen todos los

descuentos registrados de forma automática.*)
