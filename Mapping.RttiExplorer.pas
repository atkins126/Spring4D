(*
* Copyright (c) 2012, Linas Naginionis
* Contacts: lnaginionis@gmail.com or support@soundvibe.net
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions are met:
*     * Redistributions of source code must retain the above copyright
*       notice, this list of conditions and the following disclaimer.
*     * Redistributions in binary form must reproduce the above copyright
*       notice, this list of conditions and the following disclaimer in the
*       documentation and/or other materials provided with the distribution.
*     * Neither the name of the <organization> nor the
*       names of its contributors may be used to endorse or promote products
*       derived from this software without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE AUTHOR ''AS IS'' AND ANY
* EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
* DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
* DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
* (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
* LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
* ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
* (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
* SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*)
unit Mapping.RttiExplorer;

interface

uses
  Rtti, Generics.Collections, Mapping.Attributes, TypInfo, Core.Interfaces;

type
  TRttiExplorer = class
  private
    class var FCtx: TRttiContext;
  public
    class function Clone(AEntity: TObject): TObject;
    class function CreateNewClass<T>: T;
    class function CreateNewInterface(AInterfaceTypeInfo: PTypeInfo; AClassTypeInfo: PTypeInfo): IInvokable; overload;
    class function CreateNewInterface<TInterfaceType, TClassType>: TInterfaceType; overload;
    class function CreateType(AClass: TClass): TObject; overload;
    class function CreateType(ATypeInfo: PTypeInfo): TObject; overload;
    class function EntityChanged(AEntity1, AEntity2: TObject): Boolean;
    class function GetAsRecord(ARttiObject: TRttiNamedObject): TRttiRecordType;
    class function GetAssociations(AClass: TClass): TList<Association>;
    class function GetAutoGeneratedColumnMemberName(AClass: TClass): string;
    class function GetChangedMembers(AOriginalObj, ADirtyObj: TObject): TList<ColumnAttribute>; overload;
    class function GetClassAttribute<T: TORMAttribute>(AClass: TClass): T;
    class function GetClassMembers<T: TORMAttribute>(AClass: TClass): TList<T>; overload;
    class function GetColumns(AClass: TClass): TList<ColumnAttribute>; overload;
    class function GetColumnIsIdentity(AClass: TClass; AColumn: ColumnAttribute): Boolean;
    class procedure GetDeclaredConstructors(AClass: TClass; AList: TList<TRttiMethod>);
    class function GetMethodWithLessParameters(AList: TList<TRttiMethod>): TRttiMethod;
    class function GetEntities(): TList<TClass>;
    class function GetEntityRttiType(ATypeInfo: PTypeInfo): TRttiType; overload;
    class function GetEntityRttiType<T>(): TRttiType; overload;
    class function GetLastGenericArgumentType(ATypeInfo: PTypeInfo): TRttiType;
    class function GetForeignKeyColumn(AClass: TClass; const ABaseTablePrimaryKeyColumn: ColumnAttribute): ForeignJoinColumnAttribute;
    class function GetMemberValue(AEntity: TObject; const AMember: TRttiNamedObject): TValue; overload;
    class function GetMemberValue(AEntity: TObject; const AMemberName: string): TValue; overload;
    class function GetMemberValue(AEntity: TObject; const AMembername: string; out ARttiMember: TRttiNamedObject): TValue; overload;
    class function GetMemberValueDeep(AEntity: TObject; const AMemberName: string): TValue;
    class function GetPrimaryKeyColumn(AClass: TClass): ColumnAttribute;
    class function GetPrimaryKeyColumnMemberName(AClass: TClass): string;
    class function GetPrimaryKeyColumnName(AClass: TClass): string;
    class function GetPrimaryKeyValue(AEntity: TObject): TValue;
    class function GetRttiType(AEntity: TClass): TRttiType;
    class function GetSequence(AClass: TClass): SequenceAttribute;
    class function GetTable(AClass: TClass): TableAttribute;
    class function GetMemberTypeInfo(AClass: TClass; const AMemberName: string): PTypeInfo;
    class function GetUniqueConstraints(AClass: TClass): TList<UniqueConstraint>;
    class function HasSequence(AClass: TClass): Boolean;
    class function TryGetBasicMethod(const AMethodName: string; ATypeInfo: PTypeInfo; out AMethod: TRttiMethod): Boolean;
    class function TryGetColumnByMemberName(AClass: TClass; const AClassMemberName: string; out AColumn: ColumnAttribute): Boolean;
    class function TryGetEntityClass(ATypeInfo: PTypeInfo; out AClass: TClass): Boolean; overload;
    class function TryGetEntityClass<T>(out AClass: TClass): Boolean; overload;
    class function TryGetPrimaryKeyValue(AColumns: TList<ColumnAttribute>; AResultset: IDBResultset; out AValue: TValue; out AColumn: ColumnAttribute): Boolean;
    class procedure CopyFieldValues(AEntityFrom, AEntityTo: TObject);
    class procedure DestroyClass<T>(var AObject: T);
    class procedure GetChangedMembers(AOriginalObj, ADirtyObj: TObject; AList: TList<ColumnAttribute>); overload;
    class procedure GetClassMembers<T: TORMAttribute>(AClass: TClass; AList: TList<T>); overload;
    class procedure GetColumns(AClass: TClass; AColumns: TList<ColumnAttribute>); overload;
    class procedure SetMemberValue(AManager: TObject; AEntity: TObject; const AMemberColumn: ColumnAttribute; const AValue: TValue); overload;
    class procedure SetMemberValue(AManager: TObject; AEntity: TObject; const AMemberName: string; const AValue: TValue); overload;
    class procedure SetMemberValueSimple(AEntity: TObject; const AMemberName: string; const AValue: TValue);
  end;

implementation

uses
  Core.Exceptions
  ,Core.Reflection
  ,Core.EntityCache
  ,Core.Utils
  ,SysUtils
  ,Math
  ,Classes
  ;

(*
  Copyright (c) 2011, Stefan Glienke
  All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:

  - Redistributions of source code must retain the above copyright notice,
    this list of conditions and the following disclaimer.
  - Redistributions in binary form must reproduce the above copyright notice,
    this list of conditions and the following disclaimer in the documentation
    and/or other materials provided with the distribution.
  - Neither the name of this library nor the names of its contributors may be
    used to endorse or promote products derived from this software without
    specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
  POSSIBILITY OF SUCH DAMAGE.
*)  

function ValueIsEqual(const Left, Right: TValue): Boolean;
begin  
  if Left.IsNumeric and Right.IsNumeric then
  begin
    if Left.IsOrdinal then
    begin
      if Right.IsOrdinal then
      begin
        Result := Left.AsOrdinal = Right.AsOrdinal;
      end else
      if Right.IsSingle then
      begin
        Result := Math.SameValue(Left.AsOrdinal, Right.AsSingle);
      end else
      if Right.IsDouble then
      begin
        Result := Math.SameValue(Left.AsOrdinal, Right.AsDouble);
      end
      else
      begin
        Result := Math.SameValue(Left.AsOrdinal, Right.AsExtended);
      end;
    end else
    if Left.IsSingle then
    begin
      if Right.IsOrdinal then
      begin
        Result := Math.SameValue(Left.AsSingle, Right.AsOrdinal);
      end else
      if Right.IsSingle then
      begin
        Result := Math.SameValue(Left.AsSingle, Right.AsSingle);
      end else
      if Right.IsDouble then
      begin
        Result := Math.SameValue(Left.AsSingle, Right.AsDouble);
      end
      else
      begin
        Result := Math.SameValue(Left.AsSingle, Right.AsExtended);
      end;
    end else
    if Left.IsDouble then
    begin
      if Right.IsOrdinal then
      begin
        Result := Math.SameValue(Left.AsDouble, Right.AsOrdinal);
      end else
      if Right.IsSingle then
      begin
        Result := Math.SameValue(Left.AsDouble, Right.AsSingle);
      end else
      if Right.IsDouble then
      begin
        Result := Math.SameValue(Left.AsDouble, Right.AsDouble);
      end
      else
      begin
        Result := Math.SameValue(Left.AsDouble, Right.AsExtended);
      end;
    end
    else
    begin
      if Right.IsOrdinal then
      begin
        Result := Math.SameValue(Left.AsExtended, Right.AsOrdinal);
      end else
      if Right.IsSingle then
      begin
        Result := Math.SameValue(Left.AsExtended, Right.AsSingle);
      end else
      if Right.IsDouble then
      begin
        Result := Math.SameValue(Left.AsExtended, Right.AsDouble);
      end
      else
      begin
        Result := Math.SameValue(Left.AsExtended, Right.AsExtended);
      end;
    end;
  end else
  if Left.IsString and Right.IsString then
  begin
    Result := Left.AsString = Right.AsString;
  end else
  if Left.IsClass and Right.IsClass then
  begin
    Result := Left.AsClass = Right.AsClass;
  end else
  if Left.IsObject and Right.IsObject then
  begin
    Result := Left.AsObject = Right.AsObject;
  end else
  if Left.IsVariant and Right.IsVariant then
  begin
    Result := Left.AsVariant = Right.AsVariant;
  end else
  if Left.IsPointer and Right.IsPointer then
  begin
    Result := Left.AsPointer = Right.AsPointer;
  end else
  if Left.TypeInfo = Right.TypeInfo then
  begin
    Result := Left.AsPointer = Right.AsPointer;
  end else
  begin
    Result := False;
  end;
end;


{ TRttiExplorer }

class function TRttiExplorer.Clone(AEntity: TObject): TObject;
begin
  Assert(Assigned(AEntity));

  Result := AEntity.ClassType.Create;
  CopyFieldValues(AEntity, Result);
end;

class procedure TRttiExplorer.CopyFieldValues(AEntityFrom, AEntityTo: TObject);
var
  LField: TRttiField;
  LType: TRttiType;
  LValue, LValueInstance: TValue;
  LObj: TObject;
begin
  Assert(AEntityFrom.ClassType = AEntityTo.ClassType);
  Assert(Assigned(AEntityFrom) and Assigned(AEntityTo));

  LType := FCtx.GetType(AEntityFrom.ClassInfo);
  for LField in LType.GetFields do
  begin
    if LField.FieldType.IsInstance then
    begin
      LValue := TRttiExplorer.CreateType(LField.FieldType.AsInstance.MetaclassType);
      LObj := LValue.AsObject;
      LValueInstance := LField.GetValue(AEntityFrom);
      if LObj is TPersistent then
      begin
        TPersistent(LObj).Assign(LValueInstance.AsObject as TPersistent);
      end;
    end
    else
      LValue := LField.GetValue(AEntityFrom);

    LField.SetValue(AEntityTo, LValue);
  end;
  {TODO -oLinas -cGeneral : what to do with properties? Should we need to write them too?}
end;

class function TRttiExplorer.CreateNewClass<T>: T;
var
  rType: TRttiType;
  AMethCreate: TRttiMethod;
  instanceType: TRttiInstanceType;
begin
  rType := TRttiContext.Create.GetType(TypeInfo(T));
  if rType.IsInstance then
  begin
    for AMethCreate in rType.GetMethods do
    begin
      if (AMethCreate.IsConstructor) and (Length(AMethCreate.GetParameters) = 0) then
      begin
        instanceType := rType.AsInstance;

        Result := AMethCreate.Invoke(instanceType.MetaclassType, []).AsType<T>;

        Break;
      end;
    end;
  end;
end;

class function TRttiExplorer.CreateNewInterface(AInterfaceTypeInfo, AClassTypeInfo: PTypeInfo): IInvokable;
var
  rType: TRttiType;
begin
  rType := TRttiContext.Create.GetType(AInterfaceTypeInfo);
  if rType.IsInterface then
  begin
    Supports(CreateType(AClassTypeInfo), rType.AsInterface.GUID, Result);
  end;
end;

class function TRttiExplorer.CreateNewInterface<TInterfaceType, TClassType>: TInterfaceType;
var
  rType: TRttiType;
begin
  rType := TRttiContext.Create.GetType(TypeInfo(TInterfaceType));
  if rType.IsInterface then
  begin
    Supports(CreateType(TypeInfo(TClassType)), rType.AsInterface.GUID, Result);
  end;
end;

class function TRttiExplorer.CreateType(ATypeInfo: PTypeInfo): TObject;
var
  rType: TRttiType;
  AMethCreate: TRttiMethod;
  instanceType: TRttiInstanceType;
begin
  rType := TRttiContext.Create.GetType(ATypeInfo);
  if rType.IsInstance then
  begin
    for AMethCreate in rType.GetMethods do
    begin
      if (AMethCreate.IsConstructor) and (Length(AMethCreate.GetParameters) = 0) then
      begin
        instanceType := rType.AsInstance;

        Result := AMethCreate.Invoke(instanceType.MetaclassType, []).AsObject;

        Exit;
      end;
    end;
  end;
  Result := nil;
end;

class function TRttiExplorer.CreateType(AClass: TClass): TObject;
begin
  Result := AClass.Create;
end;

class procedure TRttiExplorer.DestroyClass<T>(var AObject: T);
var
  rType: TRttiType;
  AMethDestroy: TRttiMethod;
  LObject: TValue;
  LObj: TObject;
begin
  rType := TRttiContext.Create.GetType(TypeInfo(T));
  if rType.IsInstance then
  begin
    LObject := TValue.From<T>(AObject);
    if LObject.IsObject then
    begin
      LObj := LObject.AsObject;
      if Assigned(LObj) then
      begin
        for AMethDestroy in rType.GetMethods do
        begin
          if (AMethDestroy.IsDestructor) and (Length(AMethDestroy.GetParameters) = 0) then
          begin
            AMethDestroy.Invoke(LObj, []);
            Break;
          end;
        end;
      end;
    end;
  end;
end;

class function TRttiExplorer.EntityChanged(AEntity1, AEntity2: TObject): Boolean;
var
  LChangedMembers: TList<ColumnAttribute>;
begin
  LChangedMembers := GetChangedMembers(AEntity1, AEntity2);
  try
    Result := (LChangedMembers.Count > 0);
  finally
    LChangedMembers.Free;
  end;
end;

class function TRttiExplorer.GetAsRecord(ARttiObject: TRttiNamedObject): TRttiRecordType;
begin
  Result := nil;
  if ARttiObject is TRttiProperty then
    Result := TRttiProperty(ARttiObject).PropertyType.AsRecord
  else if ARttiObject is TRttiField then
    Result := TRttiField(ARttiObject).FieldType.AsRecord;
end;

class function TRttiExplorer.GetAssociations(AClass: TClass): TList<Association>;
begin
  Result := GetClassMembers<Association>(AClass);
end;

class function TRttiExplorer.GetAutoGeneratedColumnMemberName(AClass: TClass): string;
var
  LIds: TList<AutoGenerated>;
begin
  Result := '';

  LIds := GetClassMembers<AutoGenerated>(AClass);
  try
    if LIds.Count > 0 then
    begin
      Result := LIds.First.ClassMemberName;
    end;
  finally
    LIds.Free;
  end;
end;

class function TRttiExplorer.GetChangedMembers(AOriginalObj, ADirtyObj: TObject): TList<ColumnAttribute>;
begin
  Result := TList<ColumnAttribute>.Create;
  GetChangedMembers(AOriginalObj, ADirtyObj, Result);
end;

class procedure TRttiExplorer.GetChangedMembers(AOriginalObj, ADirtyObj: TObject; AList: TList<ColumnAttribute>);
var
  LRttiType: TRttiType;
  LMember: TRttiMember;
  LOriginalValue, LDirtyValue: TValue;
  LCol: ColumnAttribute;
  LColumns: TList<ColumnAttribute>;
begin
  Assert(AOriginalObj.ClassType = ADirtyObj.ClassType);
  LRttiType := FCtx.GetType(AOriginalObj.ClassType);
  AList.Clear;

  LColumns := GetColumns(AOriginalObj.ClassType);
  try
    for LCol in LColumns do
    begin
      if not LCol.IsDiscriminator then
      begin

        case LCol.MemberType of
          mtField:    LMember := LRttiType.GetField(LCol.ClassMemberName);
          mtProperty: LMember := LRttiType.GetProperty(LCol.ClassMemberName);
        else
          LMember := nil;
        end;

        if not Assigned(LMember) then
          raise EUnknownMember.Create('Unknown column member: ' + LCol.ClassMemberName);

        LOriginalValue := GetMemberValue(AOriginalObj, LMember);
        LDirtyValue := GetMemberValue(ADirtyObj, LMember);

        if not Core.Reflection.SameValue(LOriginalValue, LDirtyValue) then
          AList.Add(LCol);
      end;
    end;
  finally
    LColumns.Free;
  end;
end;

class function TRttiExplorer.GetClassAttribute<T>(AClass: TClass): T;
var
  LAttr: TCustomAttribute;
  LTypeInfo: Pointer;
  LType: TRttiType;
begin
  LTypeInfo := TypeInfo(T);
  LType := FCtx.GetType(AClass);
  for LAttr in LType.GetAttributes do
  begin
    if (LAttr.ClassInfo = LTypeInfo) then
    begin
      Exit(T(LAttr));
    end;
  end;
  Result := nil;
end;

class procedure TRttiExplorer.GetClassMembers<T>(AClass: TClass; AList: TList<T>);
var
  LType: TRttiType;
  LField: TRttiField;
  LProp: TRttiProperty;
  LAttr: TCustomAttribute;
  LTypeInfo: Pointer;
begin
  AList.Clear;
  LType := FCtx.GetType(AClass);
  LTypeInfo := TypeInfo(T);
  for LField in LType.GetFields do
  begin
    for LAttr in LField.GetAttributes do
    begin
      if (LTypeInfo = LAttr.ClassInfo) then
      begin
        TORMAttribute(LAttr).MemberType := mtField;
        TORMAttribute(LAttr).ClassMemberName := LField.Name;
        TORMAttribute(LAttr).TypeInfo := LType.Handle;
        AList.Add(T(LAttr));
      end;
    end;
  end;

  for LProp in LType.GetProperties do
  begin
    for LAttr in LProp.GetAttributes do
    begin
      if (LTypeInfo = LAttr.ClassInfo) then
      begin
        TORMAttribute(LAttr).MemberType := mtProperty;
        TORMAttribute(LAttr).ClassMemberName := LProp.Name;
        TORMAttribute(LAttr).TypeInfo := LType.Handle;
        AList.Add(T(LAttr));
      end;
    end;
  end;
end;

class function TRttiExplorer.GetClassMembers<T>(AClass: TClass): TList<T>;
begin
  Result := TList<T>.Create;
  GetClassMembers<T>(AClass, Result);
end;

class function TRttiExplorer.GetColumnIsIdentity(AClass: TClass; AColumn: ColumnAttribute): Boolean;
begin
  Result := SameText(GetAutoGeneratedColumnMemberName(AClass), AColumn.ClassMemberName);
end;

class procedure TRttiExplorer.GetColumns(AClass: TClass; AColumns: TList<ColumnAttribute>);
begin
  GetClassMembers<ColumnAttribute>(AClass, AColumns);
end;

class procedure TRttiExplorer.GetDeclaredConstructors(AClass: TClass; AList: TList<TRttiMethod>);
var
  LType: TRttiType;
  LMethod: TRttiMethod;
begin
  LType := TRttiContext.Create.GetType(AClass);
  for LMethod in LType.GetDeclaredMethods do
  begin
    if LMethod.IsConstructor then
    begin
      AList.Add(LMethod);
    end;
  end;
end;

class function TRttiExplorer.GetColumns(AClass: TClass): TList<ColumnAttribute>;
begin
  Result := GetClassMembers<ColumnAttribute>(AClass);
end;

class function TRttiExplorer.TryGetBasicMethod(const AMethodName: string; ATypeInfo: PTypeInfo;
  out AMethod: TRttiMethod): Boolean;
var
  LMethod, LResultMethod: TRttiMethod;
  iParCount, iCurrParCount, iCount: Integer;
  LType: TRttiType;
begin
  Result := False;
  LMethod := nil;
  iParCount := 0;
  iCurrParCount := 0;
  LType := TRttiContext.Create.GetType(ATypeInfo);
  for LResultMethod in LType.GetMethods do
  begin
    if SameText(LResultMethod.Name, AMethodName) then
    begin
      Result := True;
      iCount := Length(LResultMethod.GetParameters);
      if (iCount < iParCount) or (iCount = 0) then
      begin
        AMethod := LResultMethod;
        Exit;
      end
      else
      begin
        if (iCount > iCurrParCount) then
        begin
          Inc(iParCount);
        end;

        iCurrParCount := iCount;
        LMethod := LResultMethod;
      end;
    end;
  end;
  AMethod := LMethod;
end;

class function TRttiExplorer.TryGetColumnByMemberName(AClass: TClass;
  const AClassMemberName: string; out AColumn: ColumnAttribute): Boolean;
var
  LCol: ColumnAttribute;
begin
  for LCol in TEntityCache.Get(AClass).Columns do
  begin
    if SameText(LCol.ClassMemberName, AClassMemberName) then
    begin
      AColumn := LCol;
      Exit(True);
    end;
  end;
  Result := False;
end;

class function TRttiExplorer.TryGetEntityClass(ATypeInfo: PTypeInfo; out AClass: TClass): Boolean;
var
  LRttiType: TRttiType;
begin
  Result := False;
  LRttiType := GetEntityRttiType(ATypeInfo);
  if Assigned(LRttiType) then
  begin
    AClass := LRttiType.AsInstance.MetaclassType;
    Result := True;
  end;
end;

class function TRttiExplorer.TryGetEntityClass<T>(out AClass: TClass): Boolean;
begin
  Result := TryGetEntityClass(TypeInfo(T), AClass);
end;

class function TRttiExplorer.TryGetPrimaryKeyValue(AColumns: TList<ColumnAttribute>;
  AResultset: IDBResultset; out AValue: TValue; out AColumn: ColumnAttribute): Boolean;
var
  LCol: ColumnAttribute;
  LVal: Variant;
begin
  for LCol in AColumns do
  begin
    if cpPrimaryKey in LCol.Properties then
    begin
      LVal := AResultset.GetFieldValue(LCol.Name);
      AValue := TUtils.FromVariant(LVal);
      AColumn := LCol;
      Exit(True);
    end;
  end;
  Result := False;
end;

class function TRttiExplorer.GetEntities: TList<TClass>;
var
  LType: TRttiType;
  LClass: TClass;
  LEntity: EntityAttribute;
begin
  Result := TList<TClass>.Create;

  for LType in TRttiContext.Create.GetTypes do
  begin
    if LType.IsInstance then
    begin
      LClass := LType.AsInstance.MetaclassType;
      LEntity := GetClassAttribute<EntityAttribute>(LClass);
      if Assigned(LEntity) then
      begin
        Result.Add(LClass);
      end;
    end;
  end;
end;

class function TRttiExplorer.GetEntityRttiType(ATypeInfo: PTypeInfo): TRttiType;
var
  LRttiType: TRttiType;
  LCurrType: TRttiType;
begin
  LRttiType := TRttiContext.Create.GetType(ATypeInfo);
  for LCurrType in LRttiType.GetGenericArguments do
  begin
    if LCurrType.IsInstance then
    begin
      if (TEntityCache.Get(LCurrType.AsInstance.MetaclassType).EntityTable <> nil) then
        Exit(LCurrType);
    end;
  end;

  if LRttiType.IsInstance then
  begin
    if (TEntityCache.Get(LRttiType.AsInstance.MetaclassType).EntityTable <> nil) then
      Exit(LRttiType);
  end;
  Result := nil;
end;

class function TRttiExplorer.GetEntityRttiType<T>(): TRttiType;
begin
  Result := GetEntityRttiType(TypeInfo(T));
end;

class function TRttiExplorer.GetForeignKeyColumn(AClass: TClass;
  const ABaseTablePrimaryKeyColumn: ColumnAttribute): ForeignJoinColumnAttribute;
var
  LForeignCol: ForeignJoinColumnAttribute;
begin
  for LForeignCol in TEntityCache.Get(AClass).ForeignColumns do
  begin
    if SameText(ABaseTablePrimaryKeyColumn.ClassMemberName, LForeignCol.ReferencedColumnName) then
    begin
      Exit(LForeignCol);
    end;
  end;
  Result := nil;
end;

class function TRttiExplorer.GetLastGenericArgumentType(ATypeInfo: PTypeInfo): TRttiType;
var
  LArgs: TArray<TRttiType>;
begin
  Result := TRttiContext.Create.GetType(ATypeInfo);
  LArgs := Result.GetGenericArguments;
  if Length(LArgs) > 0 then
  begin
    Result := LArgs[High(LArgs)];
  end;
end;

class function TRttiExplorer.GetMemberValue(AEntity: TObject; const AMember: TRttiNamedObject): TValue;
begin
  if AMember is TRttiField then
  begin
    Result := TRttiField(AMember).GetValue(AEntity);
  end
  else if AMember is TRttiProperty then
  begin
    Result := TRttiProperty(AMember).GetValue(AEntity); 
  end
  else
  begin
    Result := TValue.Empty;
  end;
end;

class function TRttiExplorer.GetPrimaryKeyColumn(AClass: TClass): ColumnAttribute;
var
  LColumns: TList<ColumnAttribute>;
  LCol: ColumnAttribute;
begin
  LColumns := GetColumns(AClass);
  try
    for LCol in LColumns do
    begin
      if (cpPrimaryKey in LCol.Properties) then
      begin
        Exit(LCol);
      end;
    end;
  finally
    LColumns.Free;
  end;
  Result := nil;
end;

class function TRttiExplorer.GetPrimaryKeyColumnMemberName(AClass: TClass): string;
var
  LCol: ColumnAttribute;
begin
  Result := '';

  LCol := GetPrimaryKeyColumn(AClass);
  if Assigned(LCol) then
  begin
    Result := LCol.ClassMemberName;
  end;
end;

class function TRttiExplorer.GetPrimaryKeyColumnName(AClass: TClass): string;
var
  LCol: ColumnAttribute;
begin
  Result := '';

  LCol := GetPrimaryKeyColumn(AClass);
  if Assigned(LCol) then
  begin
    Result := LCol.Name;
  end;
end;

class function TRttiExplorer.GetPrimaryKeyValue(AEntity: TObject): TValue;
begin
  Result := GetMemberValue(AEntity, GetPrimaryKeyColumnMemberName(AEntity.ClassType));
end;

class function TRttiExplorer.GetRttiType(AEntity: TClass): TRttiType;
begin
  Result := TRttiContext.Create.GetType(AEntity);
end;

class function TRttiExplorer.GetMemberValue(AEntity: TObject; const AMemberName: string): TValue;
var
  LMember: TRttiNamedObject;
begin
  Result := GetMemberValue(AEntity, AMemberName, LMember);
end;

class function TRttiExplorer.GetMemberTypeInfo(AClass: TClass; const AMemberName: string): PTypeInfo;
var
  LType: TRttiType;
  LField: TRttiField;
  LProp: TRttiProperty;
begin
  Result := nil;
  LType := TRttiContext.Create.GetType(AClass);
  LField := LType.GetField(AMemberName);
  if Assigned(LField) then
  begin
    Result := LField.FieldType.Handle;
  end
  else
  begin
    LProp := LType.GetProperty(AMemberName);
    if Assigned(LProp) then
    begin
      Result := LProp.PropertyType.Handle;
    end;
  end;
end;

class function TRttiExplorer.GetMemberValue(AEntity: TObject; const AMembername: string;
  out ARttiMember: TRttiNamedObject): TValue;
var
  LField: TRttiField;
  LProp: TRttiProperty;
begin
  LField := FCtx.GetType(AEntity.ClassInfo).GetField(AMemberName);
  if Assigned(LField) then
  begin
    Result := LField.GetValue(AEntity);
    ARttiMember := LField;
    Exit;
  end;

  LProp := FCtx.GetType(AEntity.ClassInfo).GetProperty(AMemberName);
  if Assigned(LProp) then
  begin
    Result := LProp.GetValue(AEntity);
    ARttiMember := LProp;
    Exit;
  end;

  Result := TValue.Empty;
end;

class function TRttiExplorer.GetMemberValueDeep(AEntity: TObject;
  const AMemberName: string): TValue;
var
  LMember: TRttiNamedObject;
  LType: TRttiType;
  LRecordField: TRttiField;
  LInterfaceMethod: TRttiMethod;
begin
  Result := GetMemberValue(AEntity, AMemberName, LMember);

  if Result.IsEmpty then
    Exit;

  LType := LMember.GetType;
  if TUtils.IsNullableType(Result.TypeInfo) then
  begin
    if LType is TRttiRecordType then
    begin
      LRecordField := TRttiRecordType(LType).GetField('FHasValue');
      if LRecordField.GetValue(Result.GetReferenceToRawData).AsBoolean then
      begin
        LRecordField := TRttiRecordType(LType).GetField('FValue');
        Result := LRecordField.GetValue(Result.GetReferenceToRawData);
      end
      else
      begin
        Result := TValue.Empty;
      end;
    end;
  end
  else if TUtils.IsLazyType(Result.TypeInfo) then
  begin
    if LType is TRttiRecordType then
    begin
      LRecordField := TRttiRecordType(LType).GetField('FLazy');
      Result := LRecordField.GetValue(Result.GetReferenceToRawData);
      LType := Result.GetType;

      if Result.AsInterface = nil then
        Exit(TValue.Empty);

      LInterfaceMethod := LType.AsInterface.GetMethod('ValueCreated');
      if LInterfaceMethod.Invoke(Result, []).AsBoolean then
      begin
        LInterfaceMethod := LType.AsInterface.GetMethod('GetValue');
        Result := LInterfaceMethod.Invoke(Result, []);
      end
      else
      begin
        Result := TValue.Empty;
      end;
    end;
  end;
end;

class function TRttiExplorer.GetMethodWithLessParameters(AList: TList<TRttiMethod>): TRttiMethod;
var
  i, iParams, iParamsOld, ix: Integer;
begin
  Assert(AList.Count > 0);
  ix := 0;
  iParamsOld := Length(AList[0].GetParameters);
  for i := 1 to AList.Count - 1 do
  begin
    iParams := Length(AList[i].GetParameters);
    if iParams < iParamsOld then
    begin
      iParamsOld := iParams;
      ix := i;
    end;
  end;

  Result := AList[ix];
end;

class function TRttiExplorer.GetSequence(AClass: TClass): SequenceAttribute;
begin
  Result := GetClassAttribute<SequenceAttribute>(AClass);
end;

class function TRttiExplorer.GetTable(AClass: TClass): TableAttribute;
begin
  Result := GetClassAttribute<TableAttribute>(AClass);
end;

class function TRttiExplorer.GetUniqueConstraints(AClass: TClass): TList<UniqueConstraint>;
begin
  Result := GetClassMembers<UniqueConstraint>(AClass);
end;

class function TRttiExplorer.HasSequence(AClass: TClass): Boolean;
begin
  Result := (GetSequence(AClass) <> System.Default(SequenceAttribute) );
end;

class procedure TRttiExplorer.SetMemberValue(AManager: TObject; AEntity: TObject; const AMemberColumn: ColumnAttribute;
  const AValue: TValue);
begin
  Assert(Assigned(AMemberColumn));
  SetMemberValue(AManager, AEntity, AMemberColumn.ClassMemberName, AValue);
end;

class procedure TRttiExplorer.SetMemberValue(AManager: TObject; AEntity: TObject; const AMemberName: string; const AValue: TValue);
var
  LField: TRttiField;
  LProp: TRttiProperty;
  LValue: TValue;
  LObject: TObject;
begin
  LValue := TValue.Empty;
  LField := FCtx.GetType(AEntity.ClassInfo).GetField(AMemberName);
  if Assigned(LField) then
  begin
    if TUtils.TryConvert(AValue, AManager, LField, AEntity, LValue) then
    begin
      LField.SetValue(AEntity, LValue);
    end;
  end
  else
  begin
    LProp := FCtx.GetType(AEntity.ClassInfo).GetProperty(AMemberName);
    if Assigned(LProp) then
    begin
      if TUtils.TryConvert(AValue, AManager, LProp, AEntity, LValue) then
      begin
        LProp.SetValue(AEntity, LValue);
      end;
    end;
  end;

  if LValue.IsObject then
  begin
    LObject := LValue.AsObject;
    if Assigned(LObject) then
      LObject.Free;
  end;

  if AValue.IsObject then
  begin
    LObject := AValue.AsObject;
    if Assigned(LObject) then
      LObject.Free;
  end;
end;



class procedure TRttiExplorer.SetMemberValueSimple(AEntity: TObject; const AMemberName: string; const AValue: TValue);
var
  LType: TRttiType;
  LField: TRttiField;
  LProp: TRttiProperty;
begin
  LType := TRttiContext.Create.GetType(AEntity.ClassType);
  LField := LType.GetField(AMemberName);
  if Assigned(LField) then
  begin
    LField.SetValue(AEntity, AValue);
  end
  else
  begin
    LProp := LType.GetProperty(AMemberName);
    if Assigned(LProp) then
    begin
      LProp.SetValue(AEntity, AValue);
    end;
  end;
end;

end.
