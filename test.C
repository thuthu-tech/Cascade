void test(){
   TCanvas *c1 = new TCanvas("c1","multigraph",700,500);
   c1->SetGrid();

   TMultiGraph *mg = new TMultiGraph();
/*
   TGraph *g1 = new TGraph("neutron.txt");
  g1->SetTitle("Reduced field(V/cmTorr)for Ar/CO2 at 5mbar;Electric field(V/cm);Drift speed(cm/microsec)");
  g1->SetMarkerStyle(7);
  g1->SetMarkerColor(1);
  g1->SetLineColor(1);
  g1->SetFillColor(3);
  g1->SetLineStyle(1);
  mg->Add(g1);
*/
  TGraph *g2 = new TGraph("proton.txt");
  g2->SetTitle("Reduced field(V/cmTorr");
  g2->SetMarkerStyle(7);
  g2->SetMarkerColor(2);
  g2->SetLineColor(8);
  g2->SetFillColor(3);
  g2->SetLineStyle(2);
  mg->Add(g2);
/*
TGraph *g3 = new TGraph("gamma.txt");
  g3->SetTitle("Reduced field(V/cmTorr)for Ar/CO2 at 5mbar;Electric field(V/cm);Drift speed(cm/microsec)");
  g3->SetMarkerStyle(7);
  g3->SetMarkerColor(3);
  g3->SetLineColor(3);
  g3->SetFillColor(3);
  g3->SetLineStyle(3);
  mg->Add(g3);
*/
 mg->Draw("apl");
   mg->GetXaxis()->SetRangeUser(0,20);
   mg->GetYaxis()->SetRangeUser(1E-10,1000);
   mg->GetXaxis()->SetTitle("Excitation energy (MeV) )");
   mg->GetYaxis()->SetTitle("Cross section (mb)");

  TLegend *leg = new TLegend(0.95, 0.45, 0.86, 0.95);
  leg->SetFillColor(0);
  leg->SetTextSize(0.03);
  //leg->AddEntry(g1, "neutrons", "L");
  leg->AddEntry(g2, " protons", "L");
  //leg->AddEntry(g3, " gamma", "L");

 leg->Draw();
   gPad->Update();
   gPad->Modified();
}
