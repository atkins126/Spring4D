{***************************************************************************}
{                                                                           }
{           Spring Framework for Delphi                                     }
{                                                                           }
{           Copyright (C) 2009-2010 DevJet                                  }
{                                                                           }
{           http://www.spring4d.org                                         }
{                                                                           }
{***************************************************************************}
{                                                                           }
{  Licensed under the Apache License, Version 2.0 (the "License");          }
{  you may not use this file except in compliance with the License.         }
{  You may obtain a copy of the License at                                  }
{                                                                           }
{      http://www.apache.org/licenses/LICENSE-2.0                           }
{                                                                           }
{  Unless required by applicable law or agreed to in writing, software      }
{  distributed under the License is distributed on an "AS IS" BASIS,        }
{  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. }
{  See the License for the specific language governing permissions and      }
{  limitations under the License.                                           }
{                                                                           }
{***************************************************************************}

unit Spring.Tests.Configuration;

interface

uses
  TestFramework,
  Spring.Configuration;

type
  TTestConfiguration = class(TTestCase)
  private
    fSource: IConfigurationSource;
    fConfiguration: IConfiguration;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestConfigurationAttribute;
    procedure TestSection;
    procedure TestSectionAttribute;
  end;

implementation

uses
  Rtti,
  Spring.Configuration.Sources;

{ TTestConfiguration }

procedure TTestConfiguration.SetUp;
begin
  inherited;
  fSource := TXmlConfigurationSource.Create('logging.xml');
end;

procedure TTestConfiguration.TearDown;
begin
  fSource := nil;
  fConfiguration := nil;
  inherited TearDown;
end;

procedure TTestConfiguration.TestConfigurationAttribute;
var
  value: TValue;
begin
  fConfiguration := fSource.GetConfiguration;
  value := fConfiguration.TryGetAttribute('debug', value);
  CheckTrue(value.AsBoolean);
end;

procedure TTestConfiguration.TestSection;
begin
  fConfiguration := fSource.GetConfiguration;
  CheckEquals('appender', fConfiguration.GetSection('appender').Name);
end;

procedure TTestConfiguration.TestSectionAttribute;
var
  value: TValue;
begin
  fConfiguration := fSource.GetConfiguration;
  fConfiguration.GetSection('appender').TryGetAttribute('name', value);
  CheckEquals('console', value.ToString);
end;

end.
