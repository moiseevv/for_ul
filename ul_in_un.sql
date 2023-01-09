select 
	d.id,
	dob.nls,
	sh_pdata.contragent_get_name_short(d.contragent_id) as contragent,
	iif(dob.ao_id is null, dob.address_no_fias, sh_pdata.get_object_adress(dob.ao_id) || coalesce(','|| dob.num, '')) as addr,
	nullif(upper(dob.realty_period), 'infinity') as dob_edate,
	bs."name" as curstatus,
	f."name" as form,
	(
		select sum(o.summa*vw.vsign*pg.vsign)
    from sh_billing.operation o
	    join sh_billing.vw_oper_types vw on vw.subtype_id = o.type_id
	    	and vw.type_code in('CHARGE', 'CESSION')
	    join sh_billing.spr_oper_category pg on pg.id = o.category_id
	   where o.is_actual
	   	and o.docdate <= current_date
	   	and o.dogovor_id = d.id
	) as dog_charge,
	(
		select sum(-p.summa*vw.vsign*pg.vsign)
    from sh_billing.pays p
	    join sh_billing.vw_oper_types vw on vw.subtype_id = p.type_id
	    	and vw.type_code in('PAY')
	    join sh_billing.spr_oper_category pg on pg.id = p.category_id
	   where p.is_actual
	   	and p.docdate <= current_date
	   	and p.dogovor_id = d.id
	) as dog_pays
from sh_billing.dogovor d 
	join sh_billing.spr_dogovor_form f on f.id = d.form_id 
	join sh_billing.dogovor_current_status cs on cs.dogovor_id = d.id
	join sh_billing.spr_dogovor_business_status bs on bs.id = cs.status_id
	join sh_billing.dogovor_object dob on dob.dogovor_id = d.id
		and dob.is_actual
	join sh_pdata.spr_districts dis on dis.id = dob.district_id 
		and not coalesce(dis.is_town_district, false)
  join sh_pdata.addr_obj ad on ad.id = dob.ao_id
  	and not exists(
	  	select 1
	  	from sh_pdata.fias_get_parents(ad.fias_ao_id) pp
				join sh_pdata.service_towns ts on ts.fias_ao_id = pp.id
	    		and ts.is_actual
  	)
where d.is_actual		
	and d.form_id != 1