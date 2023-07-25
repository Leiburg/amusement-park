
#Если Сервер Или ТолстыйКлиентОбычноеПриложение Или ВнешнееСоединение Тогда

#Область ПрограммныйИнтерфейс

// Код процедур и функций

#КонецОбласти

#Область ОбработчикиСобытий

Процедура ОбработкаПроверкиЗаполнения(Отказ, ПроверяемыеРеквизиты)
	
	МаксимальнаяДоля = Константы.МаксимальнаяДоляОплатыБаллами.Получить();
	
	СуммаПродажи = ПозицииПродажи.Итог("Сумма");
	
	Если БаллыКСписанию <> 0 Тогда
		
		Если БаллыКСписанию > СуммаПродажи Тогда
			Отказ = Истина;
			Сообщение = Новый СообщениеПользователю;
			Сообщение.Текст = "Списываемые баллы не должны превышать сумму продажи";
			Сообщение.УстановитьДанные(ЭтотОбъект);
			Сообщение.Поле = "БаллыКСписанию";
			Сообщение.Сообщить();
		КонецЕсли;
		
		Если УдалитьЦена <> 0 Тогда
			Доля = БаллыКСписанию / СуммаПродажи * 100;
			Если Доля > МаксимальнаяДоля Тогда
				Отказ = Истина;
				Сообщение = Новый СообщениеПользователю;
				Сообщение.Текст = СтрШаблон("Доля списываемых баллов от суммы продажи больше допустимой (%1%%)", МаксимальнаяДоля);
				Сообщение.УстановитьДанные(ЭтотОбъект);
				Сообщение.Поле = "БаллыКСписанию";
				Сообщение.Сообщить();
			КонецЕсли;
		КонецЕсли;
		
		Если Не ЗначениеЗаполнено(Клиент) Тогда
			Отказ = Истина;
			Сообщение = Новый СообщениеПользователю;
			Сообщение.Текст = СтрШаблон("Для списания баллов необходимо указать клиента");
			Сообщение.УстановитьДанные(ЭтотОбъект);
			Сообщение.Поле = "БаллыКСписанию";
			Сообщение.Сообщить();			
		КонецЕсли;
		
	КонецЕсли;
	
КонецПроцедуры

Процедура ОбработкаПроведения(Отказ, Режим)

	Движения.АктивныеПосещения.Записывать = Истина;
	Движения.Продажи.Записывать = Истина;
	
	Запрос = Новый Запрос;
	Запрос.Текст = 
		"ВЫБРАТЬ
		|	ПродажаБилетаПозицииПродажи.Номенклатура.ВидАттракциона КАК ВидАттракциона,
		|	ПродажаБилетаПозицииПродажи.Номенклатура.КоличествоПосещений * ПродажаБилетаПозицииПродажи.Количество КАК
		|		КоличествоПосещений,
		|	ПродажаБилетаПозицииПродажи.Сумма
		|ИЗ
		|	Документ.ПродажаБилета.ПозицииПродажи КАК ПродажаБилетаПозицииПродажи
		|ГДЕ
		|	ПродажаБилетаПозицииПродажи.Ссылка = &Ссылка";
		
	Запрос.УстановитьПараметр("Ссылка", Ссылка);
	
	Выборка = Запрос.Выполнить().Выбрать();
	
	Пока Выборка.Следующий() Цикл
			
		// регистр АктивныеПосещения
		Движение = Движения.АктивныеПосещения.Добавить();
		Движение.Период = Дата;
		Движение.ВидДвижения = ВидДвиженияНакопления.Приход;
		Движение.Основание = Ссылка;
		Движение.ВидАттракциона = Выборка.ВидАттракциона;
		Движение.КоличествоПосещений = Выборка.КоличествоПосещений;
		
		// регистр Продажи
		Движение = Движения.Продажи.Добавить();
		Движение.Период = Дата;
		Движение.Клиент = Клиент;
		Движение.ВидАттракциона = Выборка.ВидАттракциона;	
		Движение.Сумма = Выборка.Сумма;		
		
	КонецЦикла;
	
	НачислитьСписатьБонусныеБаллы(Отказ);

КонецПроцедуры

#КонецОбласти

#Область СлужебныйПрограммныйИнтерфейс

// Код процедур и функций

#КонецОбласти

#Область СлужебныеПроцедурыИФункции

Процедура НачислитьСписатьБонусныеБаллы(Отказ)
	
	Движения.БонусныеБаллыКлиентов.Записывать = Истина;
	
	Если Не ЗначениеЗаполнено(Клиент) Тогда
		Возврат;
	КонецЕсли;
	
	СуммаПокупокКлиента = СуммаПокупокКлиента();
	
	ДоляНакапливаемыхБаллов = ДоляНакапливаемыхБаллов(СуммаПокупокКлиента);
	
	БаллыКНакоплению = СуммаДокумента * ДоляНакапливаемыхБаллов / 100;
	
	Если БаллыКНакоплению <> 0 Тогда
		
		Движение = Движения.БонусныеБаллыКлиентов.ДобавитьПриход();
		Движение.Период = Дата;
		Движение.Клиент = Клиент;
		Движение.Сумма = БаллыКНакоплению;
		
	КонецЕсли;
	
	Если БаллыКСписанию <> 0 Тогда
		
		Движение = Движения.БонусныеБаллыКлиентов.ДобавитьРасход();
		Движение.Период = Дата;
		Движение.Клиент = Клиент;
		Движение.Сумма = БаллыКСписанию;
	
	КонецЕсли;
			
	Движения.Записать();
	
	Запрос = Новый Запрос;
	Запрос.Текст = 
		"ВЫБРАТЬ
		|	БонусныеБаллыКлиентовОстатки.СуммаОстаток
		|ИЗ
		|	РегистрНакопления.БонусныеБаллыКлиентов.Остатки(&Период, Клиент = &Клиент) КАК БонусныеБаллыКлиентовОстатки
		|ГДЕ
		|	БонусныеБаллыКлиентовОстатки.СуммаОстаток < 0";
		
	Запрос.УстановитьПараметр("Период", Новый Граница(МоментВремени(), ВидГраницы.Включая));
	Запрос.УстановитьПараметр("Клиент", Клиент);
	
	Выборка = Запрос.Выполнить().Выбрать();
	
	Если Выборка.Следующий() Тогда
		
		Отказ = Истина;
		Сообщение = Новый СообщениеПользователю;
		Сообщение.Текст = СтрШаблон("Не хватает баллов для списания, на балансе %1", 
			Выборка.СуммаОстаток + БаллыКСписанию);
		Сообщение.УстановитьДанные(ЭтотОбъект);
		Сообщение.Поле = "БаллыКСписанию";
		Сообщение.Сообщить();
				
	КонецЕсли;
	
КонецПроцедуры

Функция СуммаПокупокКлиента()
	
	Запрос = Новый Запрос;
	Запрос.Текст = 
		"ВЫБРАТЬ
		|	ПродажиОбороты.СуммаОборот
		|ИЗ
		|	РегистрНакопления.Продажи.Обороты(, &КонецПериода,, Клиент = &Клиент) КАК ПродажиОбороты";
		
	Запрос.УстановитьПараметр("КонецПериода", Новый Граница(МоментВремени(), ВидГраницы.Исключая));
	Запрос.УстановитьПараметр("Клиент", Клиент);
	
	Выборка = Запрос.Выполнить().Выбрать();
	
	Если Выборка.Следующий() Тогда
		Возврат Выборка.СуммаОборот;
	КонецЕсли;
	
	Возврат 0;	
	
КонецФункции

Функция ДоляНакапливаемыхБаллов(СуммаПокупокКлиента)
	
	Запрос = Новый Запрос;
	Запрос.Текст =
		"ВЫБРАТЬ
		|	ШкалаБонуснойПрограммыДиапазоны.ПроцентНакопления
		|ИЗ
		|	РегистрСведений.АктуальнаяШкалаБонуснойПрограммы.СрезПоследних(&Период,) КАК
		|		АктуальнаяШкалаБонуснойПрограммыСрезПоследних
		|		ЛЕВОЕ СОЕДИНЕНИЕ Документ.ШкалаБонуснойПрограммы.Диапазоны КАК ШкалаБонуснойПрограммыДиапазоны
		|		ПО АктуальнаяШкалаБонуснойПрограммыСрезПоследних.Шкала = ШкалаБонуснойПрограммыДиапазоны.Ссылка
		|ГДЕ
		|	ШкалаБонуснойПрограммыДиапазоны.НижняяГраница <= &СуммаПокупокКлиента
		|	И (ШкалаБонуснойПрограммыДиапазоны.ВерхняяГраница > &СуммаПокупокКлиента
		|	ИЛИ ШкалаБонуснойПрограммыДиапазоны.ВерхняяГраница = 0)";
		
	Запрос.УстановитьПараметр("СуммаПокупокКлиента", СуммаПокупокКлиента);
	Запрос.УстановитьПараметр("Период", Дата);
	
	Выборка = Запрос.Выполнить().Выбрать();
	
	Если Выборка.Следующий() Тогда
		Возврат Выборка.ПроцентНакопления;
	КонецЕсли;
	
	Возврат 0;
	
КонецФункции

#КонецОбласти

#Область Инициализация

#КонецОбласти

#КонецЕсли
